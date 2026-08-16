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
    private let lock = NSLock()
    
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
    
    /// Creates an uncompressed zero-copy MTLTexture directly mapped from the hardware CVPixelBuffer.
    public func texture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        lock.lock()
        defer { lock.unlock() }
        
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
        
        let mtlTexture = CVMetalTextureGetTexture(cvTexture)
        return mtlTexture
    }
    
    /// Flushes the underlying texture cache to reclaim unused GPU memory and prevent memory leaks.
    public func flush() {
        lock.lock()
        defer { lock.unlock() }
        if let textureCache = textureCache {
            CVMetalTextureCacheFlush(textureCache, 0)
        }
    }
}
