//
//  TextureCacheManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import Metal
import CoreVideo

public final class TextureCacheManager: @unchecked Sendable {
    private var textureCache: CVMetalTextureCache?
    private let device: MTLDevice
    
    public init(device: MTLDevice) {
        self.device = device
        var cache: CVMetalTextureCache?
        let result = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        if result == kCVReturnSuccess {
            self.textureCache = cache
        } else {
            print("Failed to initialize CVMetalTextureCache: \(result)")
        }
    }
    
    public func texture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat: MTLPixelFormat = .bgra8Unorm
        
        var cvMetalTexture: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            pixelFormat,
            width,
            height,
            0,
            &cvMetalTexture
        )
        
        guard result == kCVReturnSuccess, let cvTexture = cvMetalTexture else {
            return nil
        }
        
        return CVMetalTextureGetTexture(cvTexture)
    }
    
    public func flush() {
        if let textureCache = textureCache {
            CVMetalTextureCacheFlush(textureCache, 0)
        }
    }
}
