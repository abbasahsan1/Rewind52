//
//  MetalViewRepresentable.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI
import MetalKit

public struct MetalViewRepresentable: UIViewRepresentable {
    public let renderer: MetalRenderer
    
    public init(renderer: MetalRenderer) {
        self.renderer = renderer
    }
    
    public func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = renderer.device
        mtkView.delegate = renderer
        mtkView.clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 1.0)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.preferredFramesPerSecond = 60
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.contentMode = .scaleAspectFit
        return mtkView
    }
    
    public func updateUIView(_ uiView: MTKView, context: Context) {
        // Updates handled internally via renderer
    }
}
