//
//  ProceduralNoiseGenerator.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation

public final class ProceduralNoiseGenerator: @unchecked Sendable {
    private var humPhase: Float = 0.0
    private var humPhase2: Float = 0.0
    
    public init() {}
    
    /// Injects era-accurate procedural white noise floor (default -40dB) and 60Hz/120Hz AC ground-loop hum.
    public func processBuffer(_ buffer: AVAudioPCMBuffer, hissDb: Float = -40.0, humStrength: Float = 0.25) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        let sampleRate = Float(max(8000.0, buffer.format.sampleRate))
        
        // Exact -40dB linear noise gain: pow(10.0, -40.0 / 20.0) = 0.01
        let targetHissDb = min(0.0, max(-90.0, hissDb))
        let noiseGain = pow(10.0, targetHissDb / 20.0)
        
        // 60Hz fundamental + 120Hz second harmonic AC tape motor hum
        let humGain60 = humStrength * 0.008
        let humGain120 = humStrength * 0.003
        let humPhaseInc60 = (2.0 * Float.pi * 60.0) / sampleRate
        let humPhaseInc120 = (2.0 * Float.pi * 120.0) / sampleRate
        
        for frame in 0..<frameLength {
            // High-quality white noise sample uniformly distributed in [-1.0, 1.0]
            let whiteNoise = Float.random(in: -1.0...1.0) * noiseGain
            
            // Dual-harmonic electrical tape motor hum
            let hum = sin(humPhase) * humGain60 + sin(humPhase2) * humGain120
            humPhase += humPhaseInc60
            if humPhase > 2.0 * Float.pi { humPhase -= 2.0 * Float.pi }
            humPhase2 += humPhaseInc120
            if humPhase2 > 2.0 * Float.pi { humPhase2 -= 2.0 * Float.pi }
            
            let noiseSignal = whiteNoise + hum
            
            for ch in 0..<channels {
                channelData[ch][frame] += noiseSignal
            }
        }
    }
}
