//
//  ProceduralNoiseGenerator.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation

public final class ProceduralNoiseGenerator: @unchecked Sendable {
    private var phase: Float = 0.0
    private var humPhase: Float = 0.0
    
    public init() {}
    
    /// Generates audio buffers filled with era-appropriate procedural white noise floor and 60Hz AC hum.
    public func processBuffer(_ buffer: AVAudioPCMBuffer, hissDb: Float, humStrength: Float) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        let sampleRate = Float(buffer.format.sampleRate)
        
        // Linear amplitude from dB (e.g. -40dB -> 0.01)
        let noiseGain = pow(10.0, hissDb / 20.0)
        let humGain = humStrength * 0.015
        
        let humFrequency: Float = 60.0 // 60Hz AC mains hum
        let humPhaseInc = (2.0 * Float.pi * humFrequency) / sampleRate
        
        for frame in 0..<frameLength {
            let whiteNoise = (Float.random(in: -1.0...1.0)) * noiseGain
            let hum = sin(humPhase) * humGain
            humPhase += humPhaseInc
            if humPhase > 2.0 * Float.pi { humPhase -= 2.0 * Float.pi }
            
            let combined = whiteNoise + hum
            
            for ch in 0..<channels {
                channelData[ch][frame] += combined
            }
        }
    }
}
