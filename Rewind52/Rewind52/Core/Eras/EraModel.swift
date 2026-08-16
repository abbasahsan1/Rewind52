//
//  EraModel.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import CoreGraphics

public enum EraCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case analogBroadcast = "Analog Broadcast (1975–1984)"
    case camcorderGoldenAge = "Camcorder Golden Age (1985–1994)"
    case earlyDigital = "Early Digital (1995–2004)"
    case mobileEarlySmartphone = "Mobile & Early Smartphone (2005–2014)"
    case modernReference = "Modern Smartphone (2015–2026)"
    
    public var id: String { rawValue }
    
    public var shortName: String {
        switch self {
        case .analogBroadcast: return "Analog"
        case .camcorderGoldenAge: return "Camcorder"
        case .earlyDigital: return "Digital"
        case .mobileEarlySmartphone: return "Mobile"
        case .modernReference: return "Modern"
        }
    }
}

public enum DateStampFont: String, Codable, Sendable {
    case digital7
    case vcrOSD
    case nokiaMono
    case modernClean
    case typewriter
}

public enum DateStampPosition: String, Codable, Sendable {
    case bottomLeft
    case bottomRight
    case topLeft
    case topRight
    case centerBottom
    case none
}

public enum AspectRatioType: String, Codable, Sendable {
    case standard4_3 = "4:3"
    case widescreen16_9 = "16:9"
    case portrait9_16 = "9:16"
    case custom
}

public enum AuthenticityStep: String, Codable, Sendable {
    case interlace
    case chromaBleed
    case scanLines
    case posterization
    case macroblockGrid
    case amrAudioDownsample
    case threeGPReencode
    case tubeWarmth
}

public struct VideoConfig: Codable, Sendable {
    public let resolutionWidth: Int
    public let resolutionHeight: Int
    public let frameRate: Int
    public let isInterlaced: Bool
    public let colorSpace: String
    public let shaderFunction: String
    public let autoExposureLock: Bool
    public let fixedISO: Float
    public let whiteBalanceKelvin: Float
    public let posterizeColors: Int // e.g. 256 or 0 for disabled
    public let macroblockGridSize: Int // e.g. 16 for 16x16 macroblock simulation
    public let chromaticAberrationIntensity: Float
    public let scanLineIntensity: Float
    public let trackingWobbleSpeed: Float
    public let vignetteStrength: Float
    public let noiseFloorStrength: Float
    
    public var resolution: CGSize {
        CGSize(width: resolutionWidth, height: resolutionHeight)
    }
}

public struct AudioConfig: Codable, Sendable {
    public let sampleRate: Double
    public let channels: Int
    public let bitrate: Int
    public let hissDb: Float // e.g. -40.0 dB
    public let wowFlutterHz: Float // e.g. 5.0 Hz
    public let wowFlutterDepth: Float // 0.0 - 1.0
    public let lowPassCutoffHz: Float // e.g. 10000.0
    public let highPassCutoffHz: Float // e.g. 100.0
    public let bitDepth: Int // 8, 12, 16, 24
    public let isMuffled: Bool
    public let amrEmulation: Bool
}

public struct DateStampConfig: Codable, Sendable {
    public let enabled: Bool
    public let font: DateStampFont
    public let colorHex: String
    public let position: DateStampPosition
    public let format: String
    public let blinkingRec: Bool
    public let recDotColorHex: String
    public let customTextAllowed: Bool
    public let gpsAllowed: Bool
}

public struct ExportConfig: Codable, Sendable {
    public let container: String
    public let videoCodec: String
    public let audioCodec: String
    public let nativeAspectRatio: AspectRatioType
    public let pipelineSteps: [AuthenticityStep]
}

public struct EraHistoricalInfo: Codable, Sendable {
    public let title: String
    public let year: Int
    public let summary: String
    public let hardwareHardwareNotes: String
    public let culturalContext: String
}

public struct EraModel: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let year: Int
    public let category: EraCategory
    public let isFree: Bool
    public let video: VideoConfig
    public let audio: AudioConfig
    public let dateStamp: DateStampConfig
    public let export: ExportConfig
    public let history: EraHistoricalInfo
    
    public var shortLabel: String {
        "\(year)"
    }
    
    public var displayTitle: String {
        "\(year) · \(name)"
    }
}
