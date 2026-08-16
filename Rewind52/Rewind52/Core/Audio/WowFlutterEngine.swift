//
//  WowFlutterEngine.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation

public final class WowFlutterEngine: @unchecked Sendable {
    private var lfoPhase: Float = 0.0
    private var delayBuffer: [Float] = []
    private var writeIndex: Int = 0
    private let maxDelaySamples: Int = 2048
    
    public init() {
        self.delayBuffer = Array(repeating: 0.0, count: maxDelaySamples)
    }
    
    /// Applies variable delay-line pitch & speed flutter modulation.
    public func processBuffer(_ buffer: AVAudioPCMBuffer, rateHz: Float, depth: Float) {
        guard depth > 0.001, rateHz > 0.1, let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        let sampleRate = Float(buffer.format.sampleRate)
        
        let lfoPhaseInc = (2.0 * Float.pi * rateHz) / sampleRate
        let baseDelay: Float = 50.0 // samples
        let maxModulation = depth * 35.0 // max sample deviation
        
        for frame in 0..<frameLength {
            let lfoVal = sin(lfoPhase) + 0.3 * sin(lfoPhase * 2.3) // Dual-frequency tape wobble
            lfoPhase += lfoPhaseInc
            if lfoPhase > 2.0 * Float.pi { lfoPhase -= 2.0 * Float.pi }
            
            let currentDelay = baseDelay + lfoVal * maxModulation
            
            for ch in 0..<channels {
                let sample = channelData[ch][frame]
                
                // Write into ring buffer
                let wIdx = (writeIndex + frame) % maxDelaySamples
                delayBuffer[wIdx] = sample
                
                // Read from interpolated delay index
                let readPos = Float(wIdx) - currentDelay + Float(maxDelaySamples)
                let rIdx0 = Int(readPos) % maxDelaySamples
                let rIdx1 = (rIdx0 + 1) % maxDelaySamples
                let frac = readPos - floor(readPos)
                
                let delayedSample = delayBuffer[rIdx0] * (1.0 - frac) + delayBuffer[rIdx1] * frac
                
                // Blend modulated signal with original
                channelData[ch][frame] = mix(sample, delayedSample, t: depth)
            }
        }
        
        writeIndex = (writeIndex + frameLength) % maxDelaySamples
    }
    
    private func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1.0 - t) + b * t
    }
}
