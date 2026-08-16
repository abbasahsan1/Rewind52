//
//  CameraPipelineCoordinator.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreVideo
import CoreMedia
import MetalKit
import Combine
import SwiftUI

@MainActor
public final class CameraPipelineCoordinator: NSObject, ObservableObject {
    public static let shared = CameraPipelineCoordinator()
    
    @Published public var selectedEra: EraModel = EraRegistry.shared.eras.first { $0.id == EraRegistry.shared.defaultEraId }!
    @Published public var secondaryEra: EraModel = EraRegistry.shared.eras.first { $0.id == "era_2008_nokia" }!
    
    @Published public var isRecording: Bool = false
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var isProcessingRecording: Bool = false
    @Published public var processingProgress: Double = 0.0
    @Published public var processingStage: String = ""
    
    @Published public var osdState = OSDState()
    @Published public var isAudioEffectsOn: Bool = true
    @Published public var isMultiCamActive: Bool = false
    
    public let metalRenderer: MetalRenderer? = MetalRenderer()
    public var dateStampRenderer: DateStampRenderer?
    
    private let cameraService = CameraService.shared
    private let multiCamService = MultiCamService.shared
    private let audioDSPManager = AudioDSPManager.shared
    private let galleryManager = GalleryManager.shared
    private let entitlementManager = EntitlementManager.shared
    private let sfxPlayer = AudioSFXPlayer.shared
    private let arManager = ARDateStampManager.shared
    private let liveActivityManager = AuthenticityLiveActivityManager.shared
    private let videoWriter = VideoWriter()
    
    private var recordingTimer: Timer?
    private var osdTimer: Timer?
    
    public override init() {
        super.init()
        setupEngine()
    }
    
    public func setupEngine() {
        guard let renderer = metalRenderer else { return }
        self.dateStampRenderer = DateStampRenderer(device: renderer.device)
        
        cameraService.delegate = self
        renderer.recordingDelegate = self
        audioDSPManager.recordingDelegate = self
        
        Task {
            await cameraService.configure()
            audioDSPManager.start()
            setEra(selectedEra)
            startOSDTimer()
        }
    }
    
    public func setEra(_ era: EraModel) {
        self.selectedEra = era
        metalRenderer?.setEra(era)
        audioDSPManager.setEra(era)
        cameraService.setEraConfiguration(era)
    }
    
    private func startOSDTimer() {
        osdTimer?.invalidate()
        osdTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, let dateRenderer = self.dateStampRenderer else { return }
            
            var state = self.osdState
            state.isRecording = self.isRecording
            state.recordingDuration = self.recordingDuration
            
            let osdTex = dateRenderer.renderOverlayTexture(
                era: self.selectedEra,
                state: state,
                size: CGSize(width: 1080, height: 1920)
            )
            self.metalRenderer?.updateOSDTexture(osdTex)
        }
    }
    
    public func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    public func startRecording() {
        sfxPlayer.playTapeStartSFX()
        
        let targetSize = CGSize(width: selectedEra.video.resolutionWidth, height: selectedEra.video.resolutionHeight)
        videoWriter.startRecording(era: selectedEra, outputSize: targetSize) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    self.isRecording = true
                    self.recordingDuration = 0
                    self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                        guard let self = self else { return }
                        self.recordingDuration += 1.0
                        
                        // Enforce Free Tier 60s limit
                        if self.recordingDuration >= self.entitlementManager.maxRecordingDuration {
                            self.stopRecording()
                        }
                    }
                case .failure(let error):
                    print("Failed to start recording: \(error)")
                }
            }
        }
    }
    
    public func stopRecording() {
        sfxPlayer.playTapeStopSFX()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        isProcessingRecording = true
        processingProgress = 0.0
        processingStage = "Initializing Multi-Pass Pipeline..."
        liveActivityManager.startActivity(eraName: selectedEra.name)
        
        videoWriter.finishRecording { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let rawURL):
                    Task {
                        do {
                            let processedURL = try await AuthenticityPipeline.shared.processRecording(
                                sourceURL: rawURL,
                                era: self.selectedEra
                            ) { progress, stage in
                                DispatchQueue.main.async {
                                    self.processingProgress = progress
                                    self.processingStage = stage
                                    self.liveActivityManager.updateProgress(
                                        progress: progress,
                                        status: stage,
                                        eraName: self.selectedEra.name
                                    )
                                }
                            }
                            
                            self.galleryManager.addVideo(url: processedURL, era: self.selectedEra)
                            self.isProcessingRecording = false
                            self.liveActivityManager.endActivity(finalStatus: "Bake Complete!")
                        } catch {
                            print("Authenticity pipeline error: \(error)")
                            self.galleryManager.addVideo(url: rawURL, era: self.selectedEra)
                            self.isProcessingRecording = false
                            self.liveActivityManager.endActivity(finalStatus: "Saved Raw Video")
                        }
                    }
                case .failure(let error):
                    print("Finish recording error: \(error)")
                    self.isProcessingRecording = false
                    self.liveActivityManager.endActivity(finalStatus: "Recording Failed")
                }
            }
        }
    }
    
    public func toggleAudioDSP() {
        isAudioEffectsOn.toggle()
        audioDSPManager.setAudioEffectsEnabled(isAudioEffectsOn)
    }
    
    public func toggleMultiCam(onPaywallRequired: () -> Void) {
        if !entitlementManager.canUseMultiCam {
            onPaywallRequired()
            return
        }
        
        isMultiCamActive.toggle()
        if isMultiCamActive {
            cameraService.stop()
            multiCamService.startMultiCam()
        } else {
            multiCamService.stopMultiCam()
            cameraService.start()
        }
    }
    
    public func toggleAR(onPaywallRequired: () -> Void) {
        if !entitlementManager.canUseARDateStamp {
            onPaywallRequired()
            return
        }
        
        if arManager.isARActive {
            arManager.stopARSession()
        } else {
            arManager.startARSession()
        }
    }
}

// MARK: - Delegates

extension CameraPipelineCoordinator: CameraServiceDelegate {
    public nonisolated func cameraService(_ service: CameraService, didOutput pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        Task { @MainActor in
            self.metalRenderer?.updateLatestPixelBuffer(pixelBuffer, presentationTime: presentationTime)
        }
    }
}

extension CameraPipelineCoordinator: MetalRendererRecordingDelegate {
    public nonisolated func didRenderFrame(pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        videoWriter.appendVideoFrame(pixelBuffer, presentationTime: presentationTime)
    }
}

extension CameraPipelineCoordinator: AudioDSPRecordingDelegate {
    public nonisolated func didProcessAudioBuffer(_ buffer: AVAudioPCMBuffer, presentationTime: CMTime) {
        videoWriter.appendAudioBuffer(buffer, presentationTime: presentationTime)
    }
}
