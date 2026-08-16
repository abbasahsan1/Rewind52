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

// MARK: - Era Uniforms Matching Metal Shader Struct

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
    // MARK: - Metal Core Objects
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let textureCacheManager: TextureCacheManager
    
    private var pipelineStates: [String: MTLRenderPipelineState] = [:]
    private var vertexBuffer: MTLBuffer?
    private var samplerState: MTLSamplerState?
    
    private let startTime: Date = Date()
    private var currentEra: EraModel = EraRegistry.shared.eras.first { $0.id == EraRegistry.shared.defaultEraId }!
    
    // MARK: - Frame State & Thread Synchronization
    private let frameLock = NSLock()
    private var latestPixelBuffer: CVPixelBuffer?
    private var latestPresentationTime: CMTime = .zero
    private var osdTexture: MTLTexture?
    
    public weak var recordingDelegate: MetalRendererRecordingDelegate?
    
    // Full screen quad geometry (position x, y, texCoord u, v)
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
    
    // MARK: - Frame Ingestion & Configuration
    
    public func updateLatestPixelBuffer(_ pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        frameLock.lock()
        self.latestPixelBuffer = pixelBuffer
        self.latestPresentationTime = presentationTime
        frameLock.unlock()
    }
    
    public func setEra(_ era: EraModel) {
        frameLock.lock()
        self.currentEra = era
        frameLock.unlock()
    }
    
    public func updateOSDTexture(_ texture: MTLTexture?) {
        frameLock.lock()
        self.osdTexture = texture
        frameLock.unlock()
    }
    
    // MARK: - Metal Pipeline Setup
    
    private func setupPipelines() {
        let library: MTLLibrary?
        do {
            library = try device.makeLibrary(source: ShaderSource.source, options: nil)
        } catch {
            print("Dynamic Metal shader compilation error, falling back to default library: \(error)")
            library = device.makeDefaultLibrary()
        }
        
        guard let library = library else {
            print("Failed to initialize Metal shader library")
            return
        }
        
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
            print("Failed to locate default_vertex shader function")
            return
        }
        
        let shaderNames = [
            "early_digital_fragment",
            "analog_crt_fragment",
            "camcorder_vhs_fragment",
            "mobile_3gp_fragment",
            "modern_reference_fragment",
            "overlay_composite_fragment",
            "multicam_split_fragment"
        ]
        
        for name in shaderNames {
            guard let fragmentFunction = library.makeFunction(name: name) else {
                print("Could not load shader function \(name)")
                continue
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.label = "Rewind52 \(name) Pipeline"
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            do {
                let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                pipelineStates[name] = pipelineState
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
    
    // MARK: - MTKViewDelegate & Zero-Leak Rendering Loop
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size change if needed
    }
    
    public func draw(in view: MTKView) {
        autoreleasepool {
            frameLock.lock()
            guard let pixelBuffer = latestPixelBuffer,
                  let currentDrawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor else {
                frameLock.unlock()
                return
            }
            let era = self.currentEra
            let presentationTime = self.latestPresentationTime
            frameLock.unlock()
            
            // Zero-copy transfer of CVPixelBuffer to hardware MTLTexture
            guard let inputTexture = textureCacheManager.texture(from: pixelBuffer),
                  let vertexBuffer = vertexBuffer,
                  let samplerState = samplerState,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }
            
            let shaderName = era.video.shaderFunction
            guard let pipelineState = pipelineStates[shaderName] ?? pipelineStates["early_digital_fragment"] ?? pipelineStates.values.first else {
                return
            }
            
            // Dynamic 16:9 aspect ratio calculation
            let drawableWidth = max(1.0, Float(view.drawableSize.width))
            let drawableHeight = max(1.0, Float(view.drawableSize.height))
            let viewAspect = drawableWidth / drawableHeight
            
            // Target 16:9 (0.5625 in portrait 9:16, 1.777 in landscape 16:9)
            let targetAspect: Float = (drawableHeight > drawableWidth) ? (9.0 / 16.0) : (16.0 / 9.0)
            
            var scaleX: Float = 1.0
            var scaleY: Float = 1.0
            
            if viewAspect > targetAspect {
                scaleX = targetAspect / viewAspect
            } else {
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
            
            renderEncoder.label = "Rewind52 \(shaderName) Encoder"
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 1)
            renderEncoder.setFragmentTexture(inputTexture, index: 0)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
            textureCacheManager.flush()
            
            // Notify recording delegate if capturing
            recordingDelegate?.didRenderFrame(pixelBuffer: pixelBuffer, presentationTime: presentationTime)
        }
    }
}
