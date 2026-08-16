//
//  AudioDSPManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreMedia

public protocol AudioDSPRecordingDelegate: AnyObject, Sendable {
    func didProcessAudioBuffer(_ buffer: AVAudioPCMBuffer, presentationTime: CMTime)
}

public final class AudioDSPManager: @unchecked Sendable {
    public static let shared = AudioDSPManager()
    
    // MARK: - Core Audio Graph Nodes
    private let audioEngine = AVAudioEngine()
    private let eqUnit = AVAudioUnitEQ(numberOfBands: 3)
    private let distortionUnit = AVAudioUnitDistortion()
    
    // MARK: - DSP Noise & Modulation Generators
    private let noiseGenerator = ProceduralNoiseGenerator()
    private let wowFlutterEngine = WowFlutterEngine()
    
    private let lock = NSLock()
    private var currentEra: EraModel = EraRegistry.shared.eras.first { $0.id == EraRegistry.shared.defaultEraId }!
    private var isAudioEffectsEnabled: Bool = true
    private var isRunning: Bool = false
    
    public weak var recordingDelegate: AudioDSPRecordingDelegate?
    
    private init() {
        setupAudioSession()
        setupAudioGraph()
    }
    
    public func setEra(_ era: EraModel) {
        lock.lock()
        self.currentEra = era
        lock.unlock()
        updateDSPParameters(for: era)
    }
    
    public func setAudioEffectsEnabled(_ enabled: Bool) {
        lock.lock()
        self.isAudioEffectsEnabled = enabled
        lock.unlock()
        
        if !enabled {
            eqUnit.bypass = true
            distortionUnit.bypass = true
        } else {
            updateDSPParameters(for: currentEra)
        }
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .videoRecording,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
    }
    
    private func setupAudioGraph() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // 1. Configure Band 0: High-Pass Filter (Low-cut rumble elimination)
        eqUnit.bands[0].filterType = .highPass
        eqUnit.bands[0].frequency = 80.0
        eqUnit.bands[0].bypass = false
        
        // 2. Configure Band 1: Parametric Mid EQ
        eqUnit.bands[1].filterType = .parametric
        eqUnit.bands[1].frequency = 1200.0
        eqUnit.bands[1].bandwidth = 1.2
        eqUnit.bands[1].gain = 1.5
        eqUnit.bands[1].bypass = false
        
        // 3. Configure Band 2: Low-Pass Filter (Tape high-end roll-off)
        eqUnit.bands[2].filterType = .lowPass
        eqUnit.bands[2].frequency = 9000.0
        eqUnit.bands[2].bypass = false
        
        // 4. Configure Distortion Unit for analog tape/pre-amp warmth
        distortionUnit.loadFactoryPreset(.multiBrokenSpeaker)
        distortionUnit.preGain = -4.0
        distortionUnit.wetDryMix = 25.0
        distortionUnit.bypass = true
        
        // 5. Attach nodes to AVAudioEngine
        audioEngine.attach(eqUnit)
        audioEngine.attach(distortionUnit)
        
        // 6. Connect Audio Graph: InputNode -> AVAudioUnitEQ -> AVAudioUnitDistortion -> AVAudioMixerNode
        audioEngine.connect(inputNode, to: eqUnit, format: inputFormat)
        audioEngine.connect(eqUnit, to: distortionUnit, format: inputFormat)
        audioEngine.connect(distortionUnit, to: audioEngine.mainMixerNode, format: inputFormat)
        
        // 7. Install Real-Time Audio Tap on inputNode for procedural DSP processing
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            self.lock.lock()
            let era = self.currentEra
            let effectsOn = self.isAudioEffectsEnabled
            self.lock.unlock()
            
            if effectsOn {
                // 1. In-Memory AMR-NB 12.2kbps Speech Codec Roundtrip
                if era.audio.amrEmulation {
                    var audioConfig = EraCodecConfig()
                    audioConfig.audioCodec = .audioAmrNb
                    audioConfig.audioSampleRate = 8000
                    audioConfig.audioBitrateBps = 12200
                    _ = LiveCodecSimulator.sharedInstance().processAudioBuffer(buffer, config: audioConfig)
                }
                
                // 2. Procedural Tape Hiss (-40dB default) + 60Hz/120Hz AC motor hum
                let hiss = (era.audio.hissDb != 0.0) ? era.audio.hissDb : -40.0
                let hum: Float = (era.category == .analogBroadcast || era.category == .camcorderGoldenAge) ? 0.35 : 0.05
                self.noiseGenerator.processBuffer(buffer, hissDb: hiss, humStrength: hum)
                
                // 3. Wow & Flutter dynamic delay-line pitch modulation (3Hz - 7Hz)
                let flutterRate = (era.audio.wowFlutterHz > 0) ? era.audio.wowFlutterHz : 5.0
                let flutterDepth = (era.audio.wowFlutterDepth > 0) ? era.audio.wowFlutterDepth : 0.45
                self.wowFlutterEngine.processBuffer(buffer, rateHz: flutterRate, depth: flutterDepth)
            }
            
            // Deliver processed audio buffer to VideoWriter recording engine
            self.recordingDelegate?.didProcessAudioBuffer(buffer, presentationTime: time.asCMTime)
        }
    }
    
    private func updateDSPParameters(for era: EraModel) {
        guard isAudioEffectsEnabled else { return }
        
        // Low-pass & High-pass cutoffs matching physical microphone diaphragms
        eqUnit.bands[0].frequency = era.audio.highPassCutoffHz
        eqUnit.bands[2].frequency = era.audio.lowPassCutoffHz
        eqUnit.bypass = false
        
        // AMR voice compression vs. vintage cassette saturation
        if era.audio.amrEmulation {
            distortionUnit.loadFactoryPreset(.multiBrokenSpeaker)
            distortionUnit.wetDryMix = 50.0
            distortionUnit.bypass = false
        } else if era.audio.isMuffled {
            distortionUnit.loadFactoryPreset(.multiDecimated1)
            distortionUnit.wetDryMix = 20.0
            distortionUnit.bypass = false
        } else {
            distortionUnit.bypass = true
        }
    }
    
    public func start() {
        guard !isRunning else { return }
        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            print("AudioDSPManager failed to start AVAudioEngine: \(error)")
        }
    }
    
    public func stop() {
        guard isRunning else { return }
        audioEngine.stop()
        isRunning = false
    }
}

extension AVAudioTime {
    var asCMTime: CMTime {
        if self.isSampleTimeValid {
            return CMTime(value: self.sampleTime, timescale: CMTimeScale(self.sampleRate))
        }
        return CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600)
    }
}
