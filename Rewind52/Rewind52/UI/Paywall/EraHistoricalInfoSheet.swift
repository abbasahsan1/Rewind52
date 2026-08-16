//
//  EraHistoricalInfoSheet.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI

public struct EraHistoricalInfoSheet: View {
    public let era: EraModel
    public let onSelectEra: () -> Void
    public let onUnlockEra: () -> Void
    
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        ZStack {
            RewindTheme.panelBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(era.year)")
                            .font(RewindTheme.monospaced(28, weight: .black))
                            .foregroundColor(RewindTheme.vintageAmber)
                        
                        Text(era.name)
                            .font(RewindTheme.tactical(20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 12)
                
                Divider().background(Color.white.opacity(0.15))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary
                        VStack(alignment: .leading, spacing: 6) {
                            Label("OVERVIEW", systemImage: "info.circle.fill")
                                .font(RewindTheme.monospaced(11, weight: .black))
                                .foregroundColor(RewindTheme.retroCyan)
                            Text(era.history.summary)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                        
                        // Hardware & Codec Replication
                        VStack(alignment: .leading, spacing: 6) {
                            Label("HARDWARE & CODEC REPLICATION", systemImage: "cpu.fill")
                                .font(RewindTheme.monospaced(11, weight: .black))
                                .foregroundColor(RewindTheme.vintageAmber)
                            Text(era.history.hardwareHardwareNotes)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(3)
                            
                            HStack(spacing: 12) {
                                TechBadge(label: "Resolution", value: "\(era.video.resolutionWidth)x\(era.video.resolutionHeight)")
                                TechBadge(label: "Frame Rate", value: "\(era.video.frameRate) fps")
                                TechBadge(label: "Color Space", value: era.video.colorSpace.uppercased())
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                        
                        // Audio DSP Profile
                        VStack(alignment: .leading, spacing: 6) {
                            Label("AUDIO DSP ENGINE", systemImage: "waveform")
                                .font(RewindTheme.monospaced(11, weight: .black))
                                .foregroundColor(RewindTheme.recCrimson)
                            
                            HStack(spacing: 12) {
                                TechBadge(label: "Hiss Floor", value: "\(Int(era.audio.hissDb)) dB")
                                TechBadge(label: "Wow/Flutter", value: "\(era.audio.wowFlutterHz) Hz")
                                TechBadge(label: "Low-Pass", value: "\(Int(era.audio.lowPassCutoffHz / 1000)) kHz")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                        
                        // Cultural Context
                        VStack(alignment: .leading, spacing: 6) {
                            Label("CULTURAL NOSTALGIA", systemImage: "film.fill")
                                .font(RewindTheme.monospaced(11, weight: .black))
                                .foregroundColor(RewindTheme.proGold)
                            Text(era.history.culturalContext)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                    }
                }
                
                // Action Button
                if entitlementManager.canAccessEra(era) {
                    Button(action: {
                        onSelectEra()
                        dismiss()
                    }) {
                        Text("SELECT \(era.year) ERA")
                            .font(RewindTheme.monospaced(15, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        dismiss()
                        onUnlockEra()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.open.fill")
                            Text("UNLOCK \(era.year) FOR $0.99 OR GET PRO")
                        }
                        .font(RewindTheme.monospaced(13, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RewindTheme.proGold)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct TechBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(RewindTheme.monospaced(9, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(RewindTheme.monospaced(11, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.4))
        .cornerRadius(6)
    }
}
