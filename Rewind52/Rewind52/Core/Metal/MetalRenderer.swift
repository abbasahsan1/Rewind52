//
//  MetalRenderer.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import Metal
import MetalKit
import CoreVideo
import CoreMedia
import SwiftUI

// Match the Metal shader uniforms struct exactly
public struct MetalEraUniforms {
    var time: Float
    var chromaticAberrationIntensity: Float
    var scanLineIntensity: Float
    var trackingWobbleSpeed: Float
    var vignetteStrength: Float
    var noiseFloorStrength: Float
    var posterizeColors: Int32
    var macroblockGridSize: Int32
    var isInterlaced: Int32
    var colorTemperatureShift: Float
    var aspectRatioScaleX: Float
    var aspectRatioScaleY: Float
}

public protocol MetalRendererRecordingDelegate: AnyObject, Sendable {
    func didRenderFrame(pixelBuffer: CVPixelBuffer, presentationTime: CMTime)
}

public final class MetalRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let textureCacheManager: TextureCacheManager
    
    private var pipelineStates: [String: MTLRenderPipelineState] = [:]
    private var overlayPipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var samplerState: MTLSamplerState?
    
    private let startTime: Date = Date()
    private var currentEra: EraModel = EraRegistry.shared.eras.first { $0.id == EraRegistry.shared.defaultEraId }!
    
    private let frameLock = NSLock()
    private var latestPixelBuffer: CVPixelBuffer?
    private var latestPresentationTime: CMTime = .zero
    
    private var osdTexture: MTLTexture?
    
    public weak var recordingDelegate: MetalRendererRecordingDelegate?
    
    // Full screen quad vertices (position x, y, texCoord u, v)
    private let quadVertices: [Float] = [
        -1.0, -1.0, 0.0, 1.0,
         1.0, -1.0, 1.0, 1.0,
        -1.0,  1.0, 0.0, 0.0,
         1.0, -1.0, 1.0, 1.0,
         1.0,  1.0, 1.0, 0.0,
        -1.0,  1.0, 0.0, 0.0
    ]
    
    public init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let device = device,
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.textureCacheManager = TextureCacheManager(device: device)
        
        super.init()
        
        setupPipelines()
        setupVertexBuffer()
        setupSamplerState()
    }
    
    public func setEra(_ era: EraModel) {
        frameLock.lock()
        self.currentEra = era
        frameLock.unlock()
    }
    
    public func updateLatestPixelBuffer(_ pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        frameLock.lock()
        self.latestPixelBuffer = pixelBuffer
        self.latestPresentationTime = presentationTime
        frameLock.unlock()
    }
    
    public func updateOSDTexture(_ texture: MTLTexture?) {
        frameLock.lock()
        self.osdTexture = texture
        frameLock.unlock()
    }
    
    private func setupPipelines() {
        let library: MTLLibrary?
        do {
            library = try device.makeLibrary(source: ShaderSource.source, options: nil)
        } catch {
            print("Dynamic metal compilation error, trying default library: \(error)")
            library = device.makeDefaultLibrary()
        }
        
        guard let library = library else {
            print("Failed to load Metal library")
            return
        }
        
        let shaderNames = [
            "analog_crt_fragment",
            "camcorder_vhs_fragment",
            "early_digital_fragment",
            "mobile_3gp_fragment",
            "modern_reference_fragment",
            "overlay_composite_fragment",
            "multicam_split_fragment"
        ]
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        guard let vertexFunction = library.makeFunction(name: "default_vertex") else {
            print("Failed to load default_vertex shader function")
            return
        }
        
        for name in shaderNames {
            guard let fragmentFunction = library.makeFunction(name: name) else {
                print("Could not load shader function \(name)")
                continue
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            // Enable alpha blending for overlay shader
            if name == "overlay_composite_fragment" {
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
            
            do {
                let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                pipelineStates[name] = pipelineState
                if name == "overlay_composite_fragment" {
                    self.overlayPipelineState = pipelineState
                }
            } catch {
                print("Failed to create pipeline state for \(name): \(error)")
            }
        }
    }
    
    private func setupVertexBuffer() {
        vertexBuffer = device.makeBuffer(
            bytes: quadVertices,
            length: quadVertices.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
    }
    
    private func setupSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    // MARK: - MTKViewDelegate
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes if needed
    }
    
    public func draw(in view: MTKView) {
        frameLock.lock()
        guard let pixelBuffer = latestPixelBuffer,
              let currentDrawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            frameLock.unlock()
            return
        }
        
        let era = self.currentEra
        let pTime = self.latestPresentationTime
        let osd = self.osdTexture
        frameLock.unlock()
        
        guard let inputTexture = textureCacheManager.texture(from: pixelBuffer),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        let shaderName = era.video.shaderFunction
        guard let pipelineState = pipelineStates[shaderName] ?? pipelineStates["modern_reference_fragment"],
              let vertexBuffer = vertexBuffer,
              let samplerState = samplerState else {
            return
        }
        
        // Calculate dynamic aspect ratio scaling
        let viewAspect = Float(view.drawableSize.width / max(1.0, view.drawableSize.height))
        let targetAspect: Float
        switch era.export.nativeAspectRatio {
        case .standard4_3:
            targetAspect = 4.0 / 3.0
        case .widescreen16_9:
            targetAspect = 16.0 / 9.0
        case .portrait9_16:
            targetAspect = 9.0 / 16.0
        case .custom:
            targetAspect = Float(era.video.resolutionWidth) / Float(max(1, era.video.resolutionHeight))
        }
        
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        if viewAspect > targetAspect {
            // Screen is wider than target aspect ratio -> scale X down (pillarbox)
            scaleX = targetAspect / viewAspect
        } else {
            // Screen is taller than target aspect ratio -> scale Y down (letterbox)
            scaleY = viewAspect / targetAspect
        }
        
        let elapsed = Float(Date().timeIntervalSince(startTime))
        var uniforms = MetalEraUniforms(
            time: elapsed,
            chromaticAberrationIntensity: era.video.chromaticAberrationIntensity,
            scanLineIntensity: era.video.scanLineIntensity,
            trackingWobbleSpeed: era.video.trackingWobbleSpeed,
            vignetteStrength: era.video.vignetteStrength,
            noiseFloorStrength: era.video.noiseFloorStrength,
            posterizeColors: Int32(era.video.posterizeColors),
            macroblockGridSize: Int32(era.video.macroblockGridSize),
            isInterlaced: era.video.isInterlaced ? 1 : 0,
            colorTemperatureShift: (era.video.whiteBalanceKelvin - 5500.0) / 3000.0,
            aspectRatioScaleX: scaleX,
            aspectRatioScaleY: scaleY
        )
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 1)
        renderEncoder.setFragmentTexture(inputTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        // Render OSD overlay if present
        if let osd = osd, let overlayPipe = overlayPipelineState {
            renderEncoder.setRenderPipelineState(overlayPipe)
            renderEncoder.setFragmentTexture(osd, index: 1)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        
        // Notify recording delegate if capturing
        recordingDelegate?.didRenderFrame(pixelBuffer: pixelBuffer, presentationTime: pTime)
    }
}
