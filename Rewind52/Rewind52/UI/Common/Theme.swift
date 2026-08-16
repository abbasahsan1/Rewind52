//
//  Theme.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI

public struct RewindTheme {
    // Backgrounds
    public static let deepBlack = Color(red: 0.04, green: 0.04, blue: 0.05)
    public static let viewfinderBlack = Color(red: 0.02, green: 0.02, blue: 0.02)
    public static let panelBackground = Color(red: 0.10, green: 0.10, blue: 0.12)
    public static let controlButtonBackground = Color(red: 0.16, green: 0.16, blue: 0.19)
    
    // Accents
    public static let retroCyan = Color(red: 0.0, green: 0.95, blue: 0.95)
    public static let vintageAmber = Color(red: 1.0, green: 0.65, blue: 0.15)
    public static let recCrimson = Color(red: 0.95, green: 0.15, blue: 0.20)
    public static let proGold = Color(red: 1.0, green: 0.82, blue: 0.30)
    
    // Gradients
    public static let brushedMetal = LinearGradient(
        colors: [Color(white: 0.25), Color(white: 0.18), Color(white: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let recButtonGradient = RadialGradient(
        colors: [recCrimson, Color(red: 0.70, green: 0.05, blue: 0.10)],
        center: .center,
        startRadius: 2,
        endRadius: 36
    )
    
    // Fonts
    public static func monospaced(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    public static func tactical(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
