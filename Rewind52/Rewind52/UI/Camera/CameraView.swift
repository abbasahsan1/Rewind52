//
//  CameraView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI
import AVFoundation
import CoreVideo
import MetalKit

public struct CameraView: View {
    @StateObject private var coordinator = CameraPipelineCoordinator.shared
    @StateObject private var cameraService = CameraService.shared
    @StateObject private var multiCamService = MultiCamService.shared
    @StateObject private var entitlementManager = EntitlementManager.shared
    @StateObject private var galleryManager = GalleryManager.shared
    @StateObject private var arManager = ARDateStampManager.shared
    
    // Sheets & Modals
    @State private var showPaywall: Bool = false
    @State private var targetPaywallEra: EraModel?
    @State private var showHistoricalInfo: Bool = false
    @State private var targetHistoricalEra: EraModel?
    @State private var showGallery: Bool = false
    @State private var showDateSettings: Bool = false
    
    public var body: some View {
        ZStack {
            RewindTheme.viewfinderBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Metal GPU Viewfinder
                ZStack(alignment: .bottomTrailing) {
                    if let renderer = coordinator.metalRenderer {
                        MetalViewRepresentable(renderer: renderer)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(RewindTheme.viewfinderBlack)
                            .overlay(ProgressView().tint(.white))
                    }
                    
                    // Multi-Cam Split View
                    if coordinator.isMultiCamActive {
                        MultiCamSplitView(
                            multiCamService: multiCamService,
                            eraA: coordinator.selectedEra,
                            eraB: coordinator.secondaryEra,
                            onSwapEras: {
                                let temp = coordinator.selectedEra
                                coordinator.selectedEra = coordinator.secondaryEra
                                coordinator.secondaryEra = temp
                            },
                            onClose: {
                                coordinator.isMultiCamActive = false
                                multiCamService.stopMultiCam()
                                cameraService.start()
                            }
                        )
                    }
                    
                    // Free Tier Watermark
                    if entitlementManager.shouldShowWatermark && !coordinator.isMultiCamActive {
                        WatermarkView()
                            .padding(14)
                    }
                    
                    // Tactical Viewfinder HUD Overlay
                    ControlsOverlayView(
                        cameraService: cameraService,
                        entitlementManager: entitlementManager,
                        isRecording: coordinator.isRecording,
                        recordingDuration: coordinator.recordingDuration,
                        selectedEra: coordinator.selectedEra,
                        latestThumbnail: galleryManager.items.first?.thumbnail,
                        isAudioEffectsOn: coordinator.isAudioEffectsOn,
                        isMultiCamActive: coordinator.isMultiCamActive,
                        isARActive: arManager.isARActive,
                        onRecordTapped: { coordinator.toggleRecording() },
                        onFlipCameraTapped: { cameraService.switchCamera() },
                        onFlashTapped: { cameraService.toggleTorch() },
                        onAudioToggleTapped: { coordinator.toggleAudioDSP() },
                        onMultiCamTapped: {
                            coordinator.toggleMultiCam {
                                targetPaywallEra = nil
                                showPaywall = true
                            }
                        },
                        onARTapped: {
                            coordinator.toggleAR {
                                targetPaywallEra = nil
                                showPaywall = true
                            }
                        },
                        onDateSettingsTapped: { showDateSettings = true },
                        onGalleryTapped: { showGallery = true },
                        onPaywallTapped: {
                            targetPaywallEra = nil
                            showPaywall = true
                        }
                    )
                }
                
                // 2. Tactical 52-Era Horizontal Timeline Selector
                EraTimelineSelector(
                    selectedEra: $coordinator.selectedEra,
                    onSelectEra: { era in
                        coordinator.setEra(era)
                    },
                    onLockedEraTapped: { lockedEra in
                        targetPaywallEra = lockedEra
                        showPaywall = true
                    },
                    onLongPressEra: { era in
                        targetHistoricalEra = era
                        showHistoricalInfo = true
                    }
                )
            }
            
            // 3. Multi-Pass Authenticity Processing HUD
            if coordinator.isProcessingRecording {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(RewindTheme.vintageAmber)
                        
                        Text("AUTHENTICITY PIPELINE")
                            .font(RewindTheme.monospaced(16, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1.5)
                        
                        Text(coordinator.processingStage.isEmpty ? "Baking authentic \(coordinator.selectedEra.year) \(coordinator.selectedEra.name) codec & hardware artifacts..." : coordinator.processingStage)
                            .font(.system(size: 13))
                            .foregroundColor(RewindTheme.vintageAmber)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Progress Bar
                        ProgressView(value: coordinator.processingProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: RewindTheme.vintageAmber))
                            .frame(width: 220)
                        
                        Text("\(Int(coordinator.processingProgress * 100))%")
                            .font(RewindTheme.monospaced(12, weight: .bold))
                            .foregroundColor(RewindTheme.vintageAmber)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(targetEra: targetPaywallEra)
        }
        .sheet(isPresented: $showHistoricalInfo) {
            if let era = targetHistoricalEra {
                EraHistoricalInfoSheet(
                    era: era,
                    onSelectEra: {
                        coordinator.setEra(era)
                    },
                    onUnlockEra: {
                        targetPaywallEra = era
                        showPaywall = true
                    }
                )
            }
        }
        .sheet(isPresented: $showGallery) {
            GalleryView()
        }
        .sheet(isPresented: $showDateSettings) {
            DateSettingsSheet(osdState: $coordinator.osdState, selectedEra: coordinator.selectedEra)
        }
    }
}
