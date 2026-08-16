//
//  WatermarkView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI

public struct WatermarkView: View {
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 9, weight: .bold))
            Text("Rewind52")
                .font(RewindTheme.monospaced(10, weight: .black))
                .tracking(1.2)
        }
        .foregroundColor(.white.opacity(0.45))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.35))
        .cornerRadius(4)
        .allowsHitTesting(false)
    }
}
