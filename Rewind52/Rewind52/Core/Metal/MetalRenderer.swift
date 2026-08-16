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
    
    // MARK: - Persistent Offscreen PixelBuffer Pool
    private var offscreenPool: CVPixelBufferPool?
    private var offscreenPoolWidth: Int = 0
    private var offscreenPoolHeight: Int = 0
    private let poolLock = NSLock()
    
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
    
    // MARK: - Persistent CVPixelBufferPool Management
    
    private func getOrCreateOffscreenPool(width: Int, height: Int) -> CVPixelBufferPool? {
        poolLock.lock()
        defer { poolLock.unlock() }
        
        if let pool = offscreenPool, offscreenPoolWidth == width, offscreenPoolHeight == height {
            return pool
        }
        
        offscreenPool = nil
        let poolAttributes: [CFString: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey: 4
        ]
        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [CFString: Any]
        ]
        
        var newPool: CVPixelBufferPool?
        let status = CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            poolAttributes as CFDictionary,
            pixelBufferAttributes as CFDictionary,
            &newPool
        )
        if status == kCVReturnSuccess, let pool = newPool {
            self.offscreenPool = pool
            self.offscreenPoolWidth = width
            self.offscreenPoolHeight = height
            return pool
        }
        return nil
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
            "passthrough_fragment",
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
            
            // Enable alpha blending for all pipeline states
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
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
    
    // MARK: - MTKViewDelegate & Offscreen Rendering Engine
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size change if needed
    }
    
    public func draw(in view: MTKView) {
        autoreleasepool {
            frameLock.lock()
            guard let pixelBuffer = latestPixelBuffer,
                  let currentDrawable = view.currentDrawable,
                  let viewPassDescriptor = view.currentRenderPassDescriptor else {
                frameLock.unlock()
                return
            }
            let era = self.currentEra
            let presentationTime = self.latestPresentationTime
            frameLock.unlock()
            
            let inWidth = CVPixelBufferGetWidth(pixelBuffer)
            let inHeight = CVPixelBufferGetHeight(pixelBuffer)
            
            // 1. Acquire offscreen CVPixelBuffer from persistent pool
            guard let pool = getOrCreateOffscreenPool(width: inWidth, height: inHeight) else { return }
            var offscreenPixelBuffer: CVPixelBuffer?
            let createStatus = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &offscreenPixelBuffer)
            guard createStatus == kCVReturnSuccess, let offscreenBuffer = offscreenPixelBuffer else { return }
            
            // 2. Map input and offscreen CVPixelBuffers to hardware MTLTextures
            guard let inputTexture = textureCacheManager.texture(from: pixelBuffer),
                  let offscreenTexture = textureCacheManager.texture(from: offscreenBuffer),
                  let vertexBuffer = vertexBuffer,
                  let samplerState = samplerState,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }
            
            let shaderName = era.video.shaderFunction
            guard let pipelineState = pipelineStates[shaderName] ?? pipelineStates["early_digital_fragment"] ?? pipelineStates.values.first,
                  let passthroughPipeline = pipelineStates["passthrough_fragment"] ?? pipelineStates["modern_reference_fragment"] else {
                return
            }
            
            // Dynamic 16:9 aspect ratio calculation for onscreen presentation
            let drawableWidth = max(1.0, Float(view.drawableSize.width))
            let drawableHeight = max(1.0, Float(view.drawableSize.height))
            let viewAspect = drawableWidth / drawableHeight
            let targetAspect: Float = (drawableHeight > drawableWidth) ? (9.0 / 16.0) : (16.0 / 9.0)
            
            var scaleX: Float = 1.0
            var scaleY: Float = 1.0
            if viewAspect > targetAspect {
                scaleX = targetAspect / viewAspect
            } else {
                scaleY = viewAspect / targetAspect
            }
            
            let elapsed = Float(Date().timeIntervalSince(startTime))
            var offscreenUniforms = MetalEraUniforms(
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
                aspectRatioScaleX: 1.0, // 1:1 native offscreen target geometry
                aspectRatioScaleY: 1.0
            )
            
            // 3. Offscreen Render Pass: Render Era Shader + OSD onto offscreenTexture
            let offscreenPassDescriptor = MTLRenderPassDescriptor()
            offscreenPassDescriptor.colorAttachments[0].texture = offscreenTexture
            offscreenPassDescriptor.colorAttachments[0].loadAction = .clear
            offscreenPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            offscreenPassDescriptor.colorAttachments[0].storeAction = .store
            
            if let offscreenEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenPassDescriptor) {
                offscreenEncoder.label = "Offscreen Era + OSD Encoder"
                offscreenEncoder.setRenderPipelineState(pipelineState)
                offscreenEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                offscreenEncoder.setVertexBytes(&offscreenUniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 1)
                offscreenEncoder.setFragmentTexture(inputTexture, index: 0)
                offscreenEncoder.setFragmentSamplerState(samplerState, index: 0)
                offscreenEncoder.setFragmentBytes(&offscreenUniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 0)
                offscreenEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                
                // Composite transparent OSD overlay onto the offscreen target
                frameLock.lock()
                let osdTex = self.osdTexture
                frameLock.unlock()
                
                if let osdTex = osdTex {
                    offscreenEncoder.setRenderPipelineState(passthroughPipeline)
                    offscreenEncoder.setFragmentTexture(osdTex, index: 0)
                    offscreenEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                }
                
                offscreenEncoder.endEncoding()
            }
            
            // 4. Send fully rendered offscreen CVPixelBuffer to recordingDelegate (contains shaders + OSD)
            recordingDelegate?.didRenderFrame(pixelBuffer: offscreenBuffer, presentationTime: presentationTime)
            
            // 5. Onscreen Viewfinder Pass: Render offscreenTexture onto view.currentDrawable with aspect ratio geometry
            var screenUniforms = MetalEraUniforms(
                time: elapsed,
                chromaticAberrationIntensity: 0,
                scanLineIntensity: 0,
                trackingWobbleSpeed: 0,
                vignetteStrength: 0,
                noiseFloorStrength: 0,
                posterizeColors: 0,
                macroblockGridSize: 0,
                isInterlaced: 0,
                colorTemperatureShift: 0,
                aspectRatioScaleX: scaleX,
                aspectRatioScaleY: scaleY
            )
            
            if let screenEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewPassDescriptor) {
                screenEncoder.label = "Onscreen Viewfinder Encoder"
                screenEncoder.setRenderPipelineState(passthroughPipeline)
                screenEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                screenEncoder.setVertexBytes(&screenUniforms, length: MemoryLayout<MetalEraUniforms>.size, index: 1)
                screenEncoder.setFragmentTexture(offscreenTexture, index: 0)
                screenEncoder.setFragmentSamplerState(samplerState, index: 0)
                screenEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                screenEncoder.endEncoding()
            }
            
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
            textureCacheManager.flush()
        }
    }
}
