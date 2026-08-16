//
//  EraTimelineSelector.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI
import UIKit

public struct EraTimelineSelector: View {
    @Binding public var selectedEra: EraModel
    public let onSelectEra: (EraModel) -> Void
    public let onLockedEraTapped: (EraModel) -> Void
    public let onLongPressEra: (EraModel) -> Void
    
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    private let allEras = EraRegistry.shared.eras
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    public init(
        selectedEra: Binding<EraModel>,
        onSelectEra: @escaping (EraModel) -> Void,
        onLockedEraTapped: @escaping (EraModel) -> Void,
        onLongPressEra: @escaping (EraModel) -> Void
    ) {
        self._selectedEra = selectedEra
        self.onSelectEra = onSelectEra
        self.onLockedEraTapped = onLockedEraTapped
        self.onLongPressEra = onLongPressEra
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // Era Metadata Bar
            HStack {
                Text(selectedEra.category.shortName.uppercased())
                    .font(RewindTheme.monospaced(10, weight: .black))
                    .foregroundColor(RewindTheme.retroCyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RewindTheme.retroCyan.opacity(0.15))
                    .cornerRadius(4)
                
                Text(selectedEra.name)
                    .font(RewindTheme.tactical(13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                if !entitlementManager.canAccessEra(selectedEra) {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("PRO")
                            .font(RewindTheme.monospaced(10, weight: .heavy))
                    }
                    .foregroundColor(RewindTheme.proGold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RewindTheme.proGold.opacity(0.2))
                    .cornerRadius(4)
                } else if selectedEra.isFree {
                    Text("FREE")
                        .font(RewindTheme.monospaced(9, weight: .black))
                        .foregroundColor(.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 16)
            
            // Horizontal Scrollable Timeline
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allEras) { era in
                            let isSelected = era.id == selectedEra.id
                            let isUnlocked = entitlementManager.canAccessEra(era)
                            
                            Button(action: {
                                haptic.impactOccurred()
                                if isUnlocked {
                                    selectedEra = era
                                    onSelectEra(era)
                                } else {
                                    onLockedEraTapped(era)
                                }
                            }) {
                                VStack(spacing: 4) {
                                    // Year Label & Lock Icon
                                    HStack(spacing: 2) {
                                        Text("\(era.year)")
                                            .font(RewindTheme.monospaced(13, weight: isSelected ? .black : .bold))
                                            .foregroundColor(isSelected ? .black : (isUnlocked ? .white : .gray))
                                        
                                        if !isUnlocked {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 8))
                                                .foregroundColor(RewindTheme.proGold)
                                        }
                                    }
                                    
                                    // Visual Indicator Dot / Bar
                                    Capsule()
                                        .fill(isSelected ? RewindTheme.vintageAmber : (era.isFree ? Color.green.opacity(0.6) : Color.white.opacity(0.2)))
                                        .frame(width: isSelected ? 24 : 6, height: 3)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? Color.white : RewindTheme.controlButtonBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? RewindTheme.vintageAmber : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(era.id)
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onEnded { _ in
                                        haptic.impactOccurred(intensity: 1.0)
                                        onLongPressEra(era)
                                    }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onAppear {
                    proxy.scrollTo(selectedEra.id, anchor: .center)
                }
                .onChange(of: selectedEra.id) { _, newId in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newId, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(RewindTheme.panelBackground)
    }
}
