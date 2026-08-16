//
//  WowFlutterEngine.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation

public final class WowFlutterEngine: @unchecked Sendable {
    private var lfoPhase1: Float = 0.0
    private var lfoPhase2: Float = 0.0
    private var delayBuffer: [Float] = []
    private var writeIndex: Int = 0
    private let maxDelaySamples: Int = 4096
    
    public init() {
        self.delayBuffer = Array(repeating: 0.0, count: maxDelaySamples)
    }
    
    /// Applies variable delay-line pitch & speed flutter modulation within the 3Hz to 7Hz frequency range.
    public func processBuffer(_ buffer: AVAudioPCMBuffer, rateHz: Float = 5.0, depth: Float = 0.45) {
        guard depth > 0.01, let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        let sampleRate = Float(max(8000.0, buffer.format.sampleRate))
        
        // Clamp frequency to authentic tape motor flutter range: 3.0 Hz to 7.0 Hz
        let primaryRate = max(3.0, min(rateHz, 7.0))
        let secondaryRate = min(7.0, primaryRate * 1.55)
        
        let lfoInc1 = (2.0 * Float.pi * primaryRate) / sampleRate
        let lfoInc2 = (2.0 * Float.pi * secondaryRate) / sampleRate
        
        let baseDelaySamples: Float = 64.0
        let maxDeviationSamples: Float = depth * 40.0 // Pitch modulation depth
        
        for frame in 0..<frameLength {
            // Dual-LFO synthesis: primary capstan flutter (3-7Hz) + sub-harmonic capstan wobble
            let lfoVal = sin(lfoPhase1) * 0.75 + sin(lfoPhase2) * 0.25
            lfoPhase1 += lfoInc1
            if lfoPhase1 > 2.0 * Float.pi { lfoPhase1 -= 2.0 * Float.pi }
            lfoPhase2 += lfoInc2
            if lfoPhase2 > 2.0 * Float.pi { lfoPhase2 -= 2.0 * Float.pi }
            
            let currentDelay = baseDelaySamples + lfoVal * maxDeviationSamples
            
            for ch in 0..<channels {
                let sample = channelData[ch][frame]
                
                // Circular ring buffer write
                let wIdx = (writeIndex + frame) % maxDelaySamples
                delayBuffer[wIdx] = sample
                
                // Read from interpolated fractional delay pointer
                let readPos = Float(wIdx) - currentDelay + Float(maxDelaySamples)
                let rIdx0 = Int(readPos) % maxDelaySamples
                let rIdx1 = (rIdx0 + 1) % maxDelaySamples
                let frac = readPos - floor(readPos)
                
                // Linear interpolation to eliminate pitch aliasing & clicking
                let delayedSample = delayBuffer[rIdx0] * (1.0 - frac) + delayBuffer[rIdx1] * frac
                
                // Blend modulated signal with dry track
                channelData[ch][frame] = sample * (1.0 - depth) + delayedSample * depth
            }
        }
        
        writeIndex = (writeIndex + frameLength) % maxDelaySamples
    }
}
