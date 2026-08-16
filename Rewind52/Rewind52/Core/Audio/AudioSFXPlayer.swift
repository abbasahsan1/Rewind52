//
//  AudioSFXPlayer.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation

public final class AudioSFXPlayer: @unchecked Sendable {
    public static let shared = AudioSFXPlayer()
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private init() {
        setupSynthEngine()
    }
    
    private func setupSynthEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
            self.audioEngine = engine
            self.playerNode = player
        } catch {
            print("Failed to start AudioSFXPlayer engine: \(error)")
        }
    }
    
    /// Plays mechanical tape start click & motor spin-up SFX.
    public func playTapeStartSFX() {
        playProceduralSFX(type: .tapeStart)
    }
    
    /// Plays mechanical tape stop clunk SFX.
    public func playTapeStopSFX() {
        playProceduralSFX(type: .tapeStop)
    }
    
    /// Plays retro digicam shutter click SFX.
    public func playShutterClickSFX() {
        playProceduralSFX(type: .shutterClick)
    }
    
    private enum SFXType {
        case tapeStart
        case tapeStop
        case shutterClick
    }
    
    private func playProceduralSFX(type: SFXType) {
        guard let playerNode = playerNode, let engine = audioEngine, engine.isRunning else { return }
        
        let sampleRate: Double = 44100.0
        let duration: Double = (type == .tapeStart ? 0.35 : (type == .tapeStop ? 0.25 : 0.12))
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }
        
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData else { return }
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            var sample: Float = 0.0
            
            switch type {
            case .tapeStart:
                // Mechanical relay click followed by motor hum ramp
                if t < 0.04 {
                    let click = sin(2.0 * .pi * 800.0 * t) * exp(-t * 120.0)
                    sample = Float(click * 0.8)
                } else {
                    let motor = sin(2.0 * .pi * (120.0 + t * 200.0) * t) * (1.0 - exp(-(t - 0.04) * 10.0)) * exp(-t * 5.0)
                    let noise = Float.random(in: -1.0...1.0) * 0.08
                    sample = Float(motor * 0.4) + noise
                }
            case .tapeStop:
                // Heavy mechanical solenoid clunk
                let clunk = sin(2.0 * .pi * 220.0 * t) * exp(-t * 40.0)
                let subThud = sin(2.0 * .pi * 80.0 * t) * exp(-t * 25.0)
                sample = Float((clunk * 0.6 + subThud * 0.5))
            case .shutterClick:
                // Crisp mechanical leaf shutter
                let click1 = sin(2.0 * .pi * 2400.0 * t) * exp(-t * 200.0)
                let click2 = (t > 0.03 ? sin(2.0 * .pi * 1800.0 * (t - 0.03)) * exp(-(t - 0.03) * 180.0) : 0.0)
                sample = Float((click1 * 0.7 + click2 * 0.5))
            }
            
            channelData[0][frame] = sample
        }
        
        playerNode.play()
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }
}
