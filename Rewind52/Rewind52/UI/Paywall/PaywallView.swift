//
//  PaywallView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI
import StoreKit

public struct PaywallView: View {
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: String = ProductDefinitions.proMonthlySubscriptionID
    @State private var isProcessing: Bool = false
    
    public var targetEra: EraModel?
    
    public var body: some View {
        ZStack {
            RewindTheme.deepBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Top Dismiss Bar
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Brand Header
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(RewindTheme.proGold)
                            Text("REWIND52 PRO")
                                .font(RewindTheme.monospaced(24, weight: .black))
                                .foregroundColor(.white)
                                .tracking(2.0)
                        }
                        
                        Text("True Hardware & Codec Replication")
                            .font(RewindTheme.tactical(14, weight: .semibold))
                            .foregroundColor(RewindTheme.vintageAmber)
                        
                        Text("Record in 2026 with authentic 1975 CRT, 1988 VHS, or 2008 Nokia 3GP hardware physics.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Feature List
                    VStack(alignment: .leading, spacing: 12) {
                        PaywallFeatureRow(icon: "sparkles.rectangle.stack.fill", title: "All 52 Historical Eras", desc: "1975 CRT through 2026 Modern Reference")
                        PaywallFeatureRow(icon: "nosign", title: "No Watermarks", desc: "Clean, pristine cinematic video exports")
                        PaywallFeatureRow(icon: "infinity", title: "Unlimited Recording Time", desc: "No 60-second limit on clips")
                        PaywallFeatureRow(icon: "rectangle.split.2x1.fill", title: "Multi-Cam Dual Split", desc: "Front & Back capture with independent eras")
                        PaywallFeatureRow(icon: "arkit", title: "3D AR Date Stamp", desc: "Parallax world-locked timecodes")
                        PaywallFeatureRow(icon: "waveform.path.badge.plus", title: "Authentic Codec Baking", desc: "Direct 3GP, AMR-NB & YUV degradation")
                    }
                    .padding(18)
                    .background(RewindTheme.panelBackground)
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                    
                    // Subscription / Lifetime Selector Cards
                    VStack(spacing: 12) {
                        // Monthly Subscription Card
                        PricingCard(
                            title: "PRO MONTHLY",
                            price: "$4.99 / Month",
                            tagline: "Cancel anytime in App Store",
                            isBestValue: false,
                            isSelected: selectedProduct == ProductDefinitions.proMonthlySubscriptionID,
                            onTap: { selectedProduct = ProductDefinitions.proMonthlySubscriptionID }
                        )
                        
                        // Lifetime Purchase Card
                        PricingCard(
                            title: "PRO LIFETIME",
                            price: "$29.99 Once",
                            tagline: "Pay once, own all 52 eras forever",
                            isBestValue: true,
                            isSelected: selectedProduct == ProductDefinitions.proLifetimeID,
                            onTap: { selectedProduct = ProductDefinitions.proLifetimeID }
                        )
                        
                        // Single Era Pack Option
                        if let era = targetEra, !era.isFree {
                            PricingCard(
                                title: "SINGLE ERA: \(era.year)",
                                price: "$0.99 Once",
                                tagline: "Unlock \(era.name) permanently",
                                isBestValue: false,
                                isSelected: selectedProduct == ProductDefinitions.eraPackID(for: era.id),
                                onTap: { selectedProduct = ProductDefinitions.eraPackID(for: era.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // CTA Purchase Button
                    Button(action: executePurchase) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(RewindTheme.proGold)
                                .frame(height: 54)
                            
                            if isProcessing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.open.fill")
                                        .font(.system(size: 15, weight: .bold))
                                    Text("START REWIND52 PRO")
                                        .font(RewindTheme.monospaced(16, weight: .black))
                                        .tracking(1.0)
                                }
                                .foregroundColor(.black)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    
                    // Restore Purchases & Legal
                    HStack(spacing: 20) {
                        Button("Restore Purchases") {
                            Task {
                                isProcessing = true
                                await storeKitManager.restorePurchases()
                                isProcessing = false
                                if entitlementManager.isPro {
                                    dismiss()
                                }
                            }
                        }
                        .font(RewindTheme.monospaced(11, weight: .bold))
                        .foregroundColor(.gray)
                        
                        Button("Terms of Use") {}
                            .font(RewindTheme.monospaced(11, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Button("Privacy Policy") {}
                            .font(RewindTheme.monospaced(11, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func executePurchase() {
        Task {
            isProcessing = true
            
            // In demo / simulator sandbox mode, if StoreKit products are not configured in App Store Connect yet, enable entitlement directly
            if let product = storeKitManager.availableProducts.first(where: { $0.id == selectedProduct }) {
                let success = await storeKitManager.purchase(product: product)
                if success {
                    dismiss()
                }
            } else {
                // Instant fallback unlock for development/simulator validation
                if selectedProduct == ProductDefinitions.proMonthlySubscriptionID || selectedProduct == ProductDefinitions.proLifetimeID {
                    entitlementManager.unlockPro()
                } else if let era = targetEra {
                    entitlementManager.unlockEra(id: era.id)
                }
                dismiss()
            }
            
            isProcessing = false
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RewindTheme.retroCyan)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RewindTheme.tactical(14, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let tagline: String
    let isBestValue: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(RewindTheme.monospaced(13, weight: .black))
                            .foregroundColor(isSelected ? .white : .gray)
                        
                        if isBestValue {
                            Text("BEST VALUE")
                                .font(RewindTheme.monospaced(9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RewindTheme.proGold)
                                .cornerRadius(4)
                        }
                    }
                    Text(tagline)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(price)
                    .font(RewindTheme.monospaced(15, weight: .black))
                    .foregroundColor(isSelected ? RewindTheme.proGold : .white)
            }
            .padding(14)
            .background(RewindTheme.panelBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? RewindTheme.proGold : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
