//
//  MultiCamSplitView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI

public struct MultiCamSplitView: View {
    @ObservedObject public var multiCamService: MultiCamService
    public let eraA: EraModel
    public let eraB: EraModel
    public let onSwapEras: () -> Void
    public let onClose: () -> Void
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 4) {
                // Top Header
                HStack {
                    Text("DUAL MULTI-CAM CAPTURE")
                        .font(RewindTheme.monospaced(12, weight: .black))
                        .foregroundColor(RewindTheme.vintageAmber)
                    
                    Spacer()
                    
                    Button(action: onSwapEras) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Swap")
                        }
                        .font(RewindTheme.monospaced(11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RewindTheme.controlButtonBackground)
                        .cornerRadius(6)
                    }
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Split Viewfinders
                HStack(spacing: 4) {
                    // Back Camera Frame (Cam A)
                    VStack {
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("BACK CAM")
                                    .font(RewindTheme.monospaced(10, weight: .black))
                                    .foregroundColor(.white)
                                Text(eraA.displayTitle)
                                    .font(RewindTheme.monospaced(9, weight: .bold))
                                    .foregroundColor(RewindTheme.retroCyan)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(6)
                        }
                    }
                    
                    // Front Camera Frame (Cam B)
                    VStack {
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.crop.square.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FRONT CAM")
                                    .font(RewindTheme.monospaced(10, weight: .black))
                                    .foregroundColor(.white)
                                Text(eraB.displayTitle)
                                    .font(RewindTheme.monospaced(9, weight: .bold))
                                    .foregroundColor(RewindTheme.vintageAmber)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .padding(6)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .cornerRadius(12)
                .padding(.horizontal, 8)
            }
        }
    }
}
