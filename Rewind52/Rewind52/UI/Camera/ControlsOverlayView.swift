//
//  ControlsOverlayView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI
import AVFoundation

public struct ControlsOverlayView: View {
    @ObservedObject public var cameraService: CameraService
    @ObservedObject public var entitlementManager: EntitlementManager
    
    public let isRecording: Bool
    public let recordingDuration: TimeInterval
    public let selectedEra: EraModel
    public let latestThumbnail: UIImage?
    public let isAudioEffectsOn: Bool
    public let isMultiCamActive: Bool
    public let isARActive: Bool
    
    public let onRecordTapped: () -> Void
    public let onFlipCameraTapped: () -> Void
    public let onFlashTapped: () -> Void
    public let onAudioToggleTapped: () -> Void
    public let onMultiCamTapped: () -> Void
    public let onARTapped: () -> Void
    public let onDateSettingsTapped: () -> Void
    public let onGalleryTapped: () -> Void
    public let onPaywallTapped: () -> Void
    
    public var body: some View {
        VStack {
            // Top HUD Bar
            HStack(spacing: 12) {
                // Flash / Torch Toggle
                Button(action: onFlashTapped) {
                    Image(systemName: cameraService.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(cameraService.isTorchOn ? RewindTheme.vintageAmber : .white)
                        .frame(width: 38, height: 38)
                        .background(RewindTheme.controlButtonBackground)
                        .clipShape(Circle())
                }
                
                // Audio DSP Toggle
                Button(action: onAudioToggleTapped) {
                    Image(systemName: isAudioEffectsOn ? "waveform" : "waveform.slash")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isAudioEffectsOn ? RewindTheme.retroCyan : .gray)
                        .frame(width: 38, height: 38)
                        .background(RewindTheme.controlButtonBackground)
                        .clipShape(Circle())
                }
                
                // Date Stamp Config Button
                Button(action: onDateSettingsTapped) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(RewindTheme.controlButtonBackground)
                        .clipShape(Circle())
                }
                
                // Multi-Cam Button (Pro)
                if cameraService.isMultiCamSupported {
                    Button(action: onMultiCamTapped) {
                        Image(systemName: "rectangle.split.2x1.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isMultiCamActive ? RewindTheme.vintageAmber : (entitlementManager.isPro ? .white : RewindTheme.proGold))
                            .frame(width: 38, height: 38)
                            .background(RewindTheme.controlButtonBackground)
                            .clipShape(Circle())
                    }
                }
                
                // AR 3D Date Stamp (Pro)
                Button(action: onARTapped) {
                    Image(systemName: "arkit")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isARActive ? RewindTheme.retroCyan : (entitlementManager.isPro ? .white : RewindTheme.proGold))
                        .frame(width: 38, height: 38)
                        .background(RewindTheme.controlButtonBackground)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Pro Badge / Paywall Trigger
                Button(action: onPaywallTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: entitlementManager.isPro ? "crown.fill" : "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text(entitlementManager.isPro ? "PRO ACTIVE" : "UPGRADE")
                            .font(RewindTheme.monospaced(11, weight: .black))
                    }
                    .foregroundColor(entitlementManager.isPro ? .black : RewindTheme.proGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(entitlementManager.isPro ? RewindTheme.proGold : RewindTheme.controlButtonBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(RewindTheme.proGold.opacity(0.6), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
            
            // Zoom Selector
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 2.0, 5.0], id: \.self) { factor in
                    let isSelected = abs(cameraService.zoomFactor - CGFloat(factor)) < 0.1
                    Button(action: {
                        cameraService.setZoom(CGFloat(factor))
                    }) {
                        Text(String(format: factor == 0.5 ? ".5x" : "%.0fx", factor))
                            .font(RewindTheme.monospaced(12, weight: isSelected ? .black : .bold))
                            .foregroundColor(isSelected ? RewindTheme.vintageAmber : .white.opacity(0.8))
                            .frame(width: 34, height: 34)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.bottom, 8)
            
            // Bottom Primary Controls
            HStack(alignment: .center, spacing: 32) {
                // Recent Gallery Button (Left)
                Button(action: onGalleryTapped) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(RewindTheme.controlButtonBackground)
                            .frame(width: 52, height: 52)
                        
                        if let thumb = latestThumbnail {
                            Image(uiImage: thumb)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Main Shutter / REC Button (Center)
                Button(action: onRecordTapped) {
                    ZStack {
                        // Outer Ring
                        Circle()
                            .stroke(isRecording ? RewindTheme.recCrimson : Color.white, lineWidth: 4)
                            .frame(width: 78, height: 78)
                        
                        // Inner Button
                        if isRecording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(RewindTheme.recCrimson)
                                .frame(width: 32, height: 32)
                        } else {
                            Circle()
                                .fill(RewindTheme.recButtonGradient)
                                .frame(width: 64, height: 64)
                        }
                    }
                }
                
                // Flip Camera Button (Right)
                Button(action: onFlipCameraTapped) {
                    ZStack {
                        Circle()
                            .fill(RewindTheme.controlButtonBackground)
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}
