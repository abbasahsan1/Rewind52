//
//  AudioDSPManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation

public protocol AudioDSPRecordingDelegate: AnyObject, Sendable {
    func didProcessAudioBuffer(_ buffer: AVAudioPCMBuffer, presentationTime: CMTime)
}

public final class AudioDSPManager: @unchecked Sendable {
    public static let shared = AudioDSPManager()
    
    private let audioEngine = AVAudioEngine()
    private let eqUnit = AVAudioUnitEQ(numberOfBands: 3)
    private let distortionUnit = AVAudioUnitDistortion()
    
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
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
    }
    
    private func setupAudioGraph() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Band 0: High-Pass Filter (Low-cut)
        eqUnit.bands[0].filterType = .highPass
        eqUnit.bands[0].frequency = 80.0
        eqUnit.bands[0].bypass = false
        
        // Band 1: Mid-band EQ
        eqUnit.bands[1].filterType = .parametric
        eqUnit.bands[1].frequency = 1000.0
        eqUnit.bands[1].bandwidth = 1.0
        eqUnit.bands[1].gain = 0.0
        eqUnit.bands[1].bypass = false
        
        // Band 2: Low-Pass Filter (High-cut)
        eqUnit.bands[2].filterType = .lowPass
        eqUnit.bands[2].frequency = 10000.0
        eqUnit.bands[2].bypass = false
        
        // Distortion unit for vintage saturation
        distortionUnit.loadFactoryPreset(.multiBrokenSpeaker)
        distortionUnit.preGain = -6.0
        distortionUnit.wetDryMix = 20.0
        distortionUnit.bypass = true
        
        audioEngine.attach(eqUnit)
        audioEngine.attach(distortionUnit)
        
        audioEngine.connect(inputNode, to: eqUnit, format: inputFormat)
        audioEngine.connect(eqUnit, to: distortionUnit, format: inputFormat)
        audioEngine.connect(distortionUnit, to: audioEngine.mainMixerNode, format: inputFormat)
        
        // Audio tap for real-time DSP noise/flutter injection and recording delegate streaming
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            self.lock.lock()
            let era = self.currentEra
            let effectsOn = self.isAudioEffectsEnabled
            self.lock.unlock()
            
            if effectsOn {
                // 1. Procedural Tape Hiss & 60Hz AC Hum
                self.noiseGenerator.processBuffer(
                    buffer,
                    hissDb: era.audio.hissDb,
                    humStrength: (era.category == .analogBroadcast ? 0.4 : 0.0)
                )
                
                // 2. Wow & Flutter Pitch / Delay Modulation
                self.wowFlutterEngine.processBuffer(
                    buffer,
                    rateHz: era.audio.wowFlutterHz,
                    depth: era.audio.wowFlutterDepth
                )
            }
            
            // Deliver to VideoWriter
            self.recordingDelegate?.didProcessAudioBuffer(buffer, presentationTime: time.asCMTime)
        }
    }
    
    private func updateDSPParameters(for era: EraModel) {
        guard isAudioEffectsEnabled else { return }
        
        // Low-pass filter (rolloff high frequencies for VHS/Early digital)
        eqUnit.bands[2].frequency = era.audio.lowPassCutoffHz
        eqUnit.bands[0].frequency = era.audio.highPassCutoffHz
        eqUnit.bypass = false
        
        // Vintage saturation / AMR emulation
        if era.audio.amrEmulation {
            distortionUnit.loadFactoryPreset(.multiBrokenSpeaker)
            distortionUnit.wetDryMix = 45.0
            distortionUnit.bypass = false
        } else if era.audio.isMuffled {
            distortionUnit.loadFactoryPreset(.multiDecimated1)
            distortionUnit.wetDryMix = 15.0
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
            print("AudioDSPManager failed to start engine: \(error)")
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
