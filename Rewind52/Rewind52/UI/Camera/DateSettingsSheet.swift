//
//  DateSettingsSheet.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI

public struct DateSettingsSheet: View {
    @Binding public var osdState: OSDState
    public let selectedEra: EraModel
    
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isCustomDateEnabled: Bool = false
    @State private var pickedDate: Date = Date()
    @State private var customText: String = ""
    @State private var fakeGPS: String = ""
    @State private var isGPSEnabled: Bool = false
    
    public var body: some View {
        ZStack {
            RewindTheme.panelBackground.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("DATE & OSD SETTINGS")
                        .font(RewindTheme.monospaced(16, weight: .black))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        saveSettings()
                        dismiss()
                    }) {
                        Text("DONE")
                            .font(RewindTheme.monospaced(14, weight: .black))
                            .foregroundColor(RewindTheme.vintageAmber)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Divider().background(Color.white.opacity(0.15))
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Custom Date Toggle & Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $isCustomDateEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Custom Date Stamp")
                                        .font(RewindTheme.tactical(14, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Set a specific date in history")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                            }
                            .tint(RewindTheme.vintageAmber)
                            
                            if isCustomDateEnabled {
                                DatePicker(
                                    "Date",
                                    selection: $pickedDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.wheel)
                                .colorScheme(.dark)
                            }
                        }
                        .padding()
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                        
                        // Custom Text String (Pro)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Custom OSD Text")
                                    .font(RewindTheme.tactical(14, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if !entitlementManager.isPro {
                                    Text("PRO")
                                        .font(RewindTheme.monospaced(10, weight: .heavy))
                                        .foregroundColor(RewindTheme.proGold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(RewindTheme.proGold.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            TextField("e.g. JAKE'S 10TH BIRTHDAY", text: $customText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(RewindTheme.monospaced(13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(6)
                                .disabled(!entitlementManager.isPro)
                        }
                        .padding()
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                        
                        // GPS Coordinate Spoofing (Pro)
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $isGPSEnabled) {
                                HStack {
                                    Text("GPS Location Spoof")
                                        .font(RewindTheme.tactical(14, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if !entitlementManager.isPro {
                                        Text("PRO")
                                            .font(RewindTheme.monospaced(10, weight: .heavy))
                                            .foregroundColor(RewindTheme.proGold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(RewindTheme.proGold.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .tint(RewindTheme.vintageAmber)
                            .disabled(!entitlementManager.isPro)
                            
                            if isGPSEnabled {
                                TextField("e.g. 34°03'N 118°14'W", text: $fakeGPS)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(RewindTheme.monospaced(13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            if let customDate = osdState.customDate {
                self.isCustomDateEnabled = true
                self.pickedDate = customDate
            }
            self.customText = osdState.customText ?? ""
            if let gps = osdState.fakeGPSCoordinates {
                self.isGPSEnabled = true
                self.fakeGPS = gps
            }
        }
    }
    
    private func saveSettings() {
        osdState.customDate = isCustomDateEnabled ? pickedDate : nil
        osdState.customText = customText.isEmpty ? nil : customText
        osdState.fakeGPSCoordinates = (isGPSEnabled && !fakeGPS.isEmpty) ? fakeGPS : nil
    }
}
