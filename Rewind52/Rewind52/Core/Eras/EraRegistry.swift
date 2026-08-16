//
//  EraRegistry.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation

public final class EraRegistry: Sendable {
    public static let shared = EraRegistry()
    
    public let eras: [EraModel]
    public let defaultEraId: String = "era_1988_vhs"
    
    public init() {
        self.eras = EraRegistry.generateAll52Eras()
    }
    
    public func era(for id: String) -> EraModel? {
        eras.first { $0.id == id }
    }
    
    public func era(forYear year: Int) -> EraModel? {
        eras.first { $0.year == year }
    }
    
    public var freeEras: [EraModel] {
        eras.filter { $0.isFree }
    }
    
    public var proEras: [EraModel] {
        eras.filter { !$0.isFree }
    }
    
    // MARK: - Master 52 Era Generator (1975 - 2026)
    private static func generateAll52Eras() -> [EraModel] {
        var list: [EraModel] = []
        
        // -------------------------------------------------------------
        // CATEGORY 1: ANALOG BROADCAST (1975–1984) - 10 Eras
        // -------------------------------------------------------------
        
        // 1975: CRT Broadcast
        list.append(EraModel(
            id: "era_1975_crt",
            name: "CRT Broadcast",
            year: 1975,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "analog_crt_fragment",
                autoExposureLock: true, fixedISO: 200, whiteBalanceKelvin: 5000,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.8, scanLineIntensity: 0.75,
                trackingWobbleSpeed: 0.8, vignetteStrength: 0.45, noiseFloorStrength: 0.35
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 64000,
                hissDb: -32.0, wowFlutterHz: 4.0, wowFlutterDepth: 0.4,
                lowPassCutoffHz: 8000, highPassCutoffHz: 120, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.scanLines, .tubeWarmth]
            ),
            history: EraHistoricalInfo(
                title: "1975 Color Tube Broadcast",
                year: 1975,
                summary: "Phosphor-coated vacuum tube displays with 525-line NTSC broadcast modulation.",
                hardwareHardwareNotes: "RCA cathode ray tube camera with heavy magnetic deflection and 60Hz power hum.",
                culturalContext: "The era of Saturday morning cartoons, disco fever, and living room console televisions."
            )
        ))
        
        // 1976: U-Matic 3/4"
        list.append(EraModel(
            id: "era_1976_umatic",
            name: "U-Matic 3/4\"",
            year: 1976,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "analog_crt_fragment",
                autoExposureLock: true, fixedISO: 250, whiteBalanceKelvin: 5200,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.5, scanLineIntensity: 0.65,
                trackingWobbleSpeed: 0.7, vignetteStrength: 0.40, noiseFloorStrength: 0.30
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -35.0, wowFlutterHz: 3.5, wowFlutterDepth: 0.35,
                lowPassCutoffHz: 9000, highPassCutoffHz: 100, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.scanLines, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1976 U-Matic ENG",
                year: 1976,
                summary: "The tape format that brought electronic news gathering to field reporters.",
                hardwareHardwareNotes: "Sony 3/4-inch magnetic tape cartridge with helical scan head drum.",
                culturalContext: "Pioneered on-the-scene television journalism and documentary filmmaking."
            )
        ))
        
        // 1977: Betamax I
        list.append(EraModel(
            id: "era_1977_betamax",
            name: "Betamax I",
            year: 1977,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "analog_crt_fragment",
                autoExposureLock: true, fixedISO: 200, whiteBalanceKelvin: 5300,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.4, scanLineIntensity: 0.60,
                trackingWobbleSpeed: 0.6, vignetteStrength: 0.35, noiseFloorStrength: 0.28
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -36.0, wowFlutterHz: 3.8, wowFlutterDepth: 0.3,
                lowPassCutoffHz: 9500, highPassCutoffHz: 90, bitDepth: 14,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.scanLines, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1977 Sony Betamax",
                year: 1977,
                summary: "High-density 1/2 inch video cassette offering superior luminance bandwidth.",
                hardwareHardwareNotes: "Direct FM carrier modulation with 250 lines horizontal resolution.",
                culturalContext: "The first consumer format allowing home time-shifting of television broadcasts."
            )
        ))
        
        // 1978: Portable VCR Deck
        list.append(EraModel(
            id: "era_1978_portable_deck",
            name: "Portable VCR Deck",
            year: 1978,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "analog_crt_fragment",
                autoExposureLock: true, fixedISO: 300, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.6, scanLineIntensity: 0.62,
                trackingWobbleSpeed: 0.75, vignetteStrength: 0.38, noiseFloorStrength: 0.32
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -34.0, wowFlutterHz: 4.2, wowFlutterDepth: 0.38,
                lowPassCutoffHz: 8500, highPassCutoffHz: 110, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.scanLines, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1978 Shoulder-Pack VCR",
                year: 1978,
                summary: "Heavy two-piece camera and shoulder recorder rig with lead-acid battery packs.",
                hardwareHardwareNotes: "Separate Vidicon tube camera tethered via multi-pin umbilical cord to VCR.",
                culturalContext: "Early home video pioneers lugged 20 lbs of gear to record family gatherings."
            )
        ))
        
        // 1979: VHS I
        list.append(EraModel(
            id: "era_1979_vhs1",
            name: "VHS I",
            year: 1979,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 320, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 2.0, scanLineIntensity: 0.70,
                trackingWobbleSpeed: 0.85, vignetteStrength: 0.35, noiseFloorStrength: 0.36
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -33.0, wowFlutterHz: 4.5, wowFlutterDepth: 0.45,
                lowPassCutoffHz: 8000, highPassCutoffHz: 120, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .vcrOSD, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed, .scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1979 JVC Victor VHS",
                year: 1979,
                summary: "Standard Play (SP) mode video tape with prominent chroma phase shift.",
                hardwareHardwareNotes: "Subcarrier heterodyne color-under recording at 629 kHz.",
                culturalContext: "The format that ignited the legendary videotape format wars."
            )
        ))
        
        // 1980: Color Tube Camera
        list.append(EraModel(
            id: "era_1980_tube_cam",
            name: "Color Tube Camera",
            year: 1980,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "analog_crt_fragment",
                autoExposureLock: true, fixedISO: 250, whiteBalanceKelvin: 5200,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.7, scanLineIntensity: 0.55,
                trackingWobbleSpeed: 0.65, vignetteStrength: 0.32, noiseFloorStrength: 0.28
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -36.0, wowFlutterHz: 3.6, wowFlutterDepth: 0.32,
                lowPassCutoffHz: 9200, highPassCutoffHz: 90, bitDepth: 12,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.scanLines, .tubeWarmth]
            ),
            history: EraHistoricalInfo(
                title: "1980 Saticon Tube",
                year: 1980,
                summary: "High-resolution selenium-arsenic-tellurium tube sensor giving soft highlight roll-off.",
                hardwareHardwareNotes: "Tri-electrode single tube color separation filter with slight lag trails.",
                culturalContext: "Signature cinematic tube trail aesthetics seen in early music videos."
            )
        ))
        
        // 1981: Betamax II
        list.append(EraModel(
            id: "era_1981_betamax2",
            name: "Betamax II",
            year: 1981,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "analog_crt_fragment",
                autoExposureLock: true, fixedISO: 200, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.2, scanLineIntensity: 0.50,
                trackingWobbleSpeed: 0.5, vignetteStrength: 0.30, noiseFloorStrength: 0.22
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 128000,
                hissDb: -42.0, wowFlutterHz: 2.8, wowFlutterDepth: 0.20,
                lowPassCutoffHz: 12000, highPassCutoffHz: 70, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .vcrOSD, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MM/dd/yyyy", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1981 Betamax II Hi-Fi",
                year: 1981,
                summary: "Second-generation Beta standard with improved linear tape audio response.",
                hardwareHardwareNotes: "20 mm/s tape speed with precision azimuth recording heads.",
                culturalContext: "Beloved by videophiles for crisp picture rendering."
            )
        ))
        
        // 1982: Compact VHS Deck
        list.append(EraModel(
            id: "era_1982_compact_vhs",
            name: "Compact VHS Deck",
            year: 1982,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 350, whiteBalanceKelvin: 5300,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.9, scanLineIntensity: 0.68,
                trackingWobbleSpeed: 0.80, vignetteStrength: 0.36, noiseFloorStrength: 0.34
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -35.0, wowFlutterHz: 4.0, wowFlutterDepth: 0.40,
                lowPassCutoffHz: 8500, highPassCutoffHz: 110, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .vcrOSD, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed, .scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1982 Early Portable VHS",
                year: 1982,
                summary: "Transition toward miniature tape transport mechanisms.",
                hardwareHardwareNotes: "Direct-drive brushless motor reel tables with quartz lock.",
                culturalContext: "Documented the birth of the home computer revolution."
            )
        ))
        
        // 1983: VHS-C
        list.append(EraModel(
            id: "era_1983_vhsc",
            name: "VHS-C",
            year: 1983,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 400, whiteBalanceKelvin: 5200,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 2.1, scanLineIntensity: 0.72,
                trackingWobbleSpeed: 0.90, vignetteStrength: 0.40, noiseFloorStrength: 0.38
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -34.0, wowFlutterHz: 4.8, wowFlutterDepth: 0.48,
                lowPassCutoffHz: 8000, highPassCutoffHz: 120, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed, .scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1983 VHS-C Compact Cassette",
                year: 1983,
                summary: "Miniature VHS cassette designed for compact handheld camcorders.",
                hardwareHardwareNotes: "20-minute compact tape playable in standard decks using motorized adapter.",
                culturalContext: "Made filming family vacations casual and ubiquitous."
            )
        ))
        
        // 1984: Video8
        list.append(EraModel(
            id: "era_1984_video8",
            name: "Video8",
            year: 1984,
            category: .analogBroadcast,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 300, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.4, scanLineIntensity: 0.55,
                trackingWobbleSpeed: 0.55, vignetteStrength: 0.32, noiseFloorStrength: 0.25
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 128000,
                hissDb: -40.0, wowFlutterHz: 3.0, wowFlutterDepth: 0.25,
                lowPassCutoffHz: 11000, highPassCutoffHz: 80, bitDepth: 14,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1984 Sony Video8 Debut",
                year: 1984,
                summary: "8mm metal-particle magnetic tape offering superior color fidelity in a palm-sized chassis.",
                hardwareHardwareNotes: "AFM (Audio Frequency Modulation) sound recorded along video helical tracks.",
                culturalContext: "The tape standard that set the stage for modern portable video."
            )
        ))
        
        // -------------------------------------------------------------
        // CATEGORY 2: CAMCORDER GOLDEN AGE (1985–1994) - 10 Eras
        // -------------------------------------------------------------
        
        // 1985: VHS HQ
        list.append(EraModel(
            id: "era_1985_vhshq",
            name: "VHS HQ",
            year: 1985,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 350, whiteBalanceKelvin: 5300,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.8, scanLineIntensity: 0.62,
                trackingWobbleSpeed: 0.70, vignetteStrength: 0.32, noiseFloorStrength: 0.30
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 128000,
                hissDb: -38.0, wowFlutterHz: 3.5, wowFlutterDepth: 0.30,
                lowPassCutoffHz: 10000, highPassCutoffHz: 90, bitDepth: 14,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .vcrOSD, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed, .scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1985 VHS High Quality",
                year: 1985,
                summary: "Luminance detail enhancement and white clip level expansion for crisper edges.",
                hardwareHardwareNotes: "HQ circuitry with line noise canceller and chroma vertical delay line.",
                culturalContext: "The golden standard of mid-80s rental cassettes."
            )
        ))
        
        // 1986: Hi8 Prototype
        list.append(EraModel(
            id: "era_1986_hi8_proto",
            name: "Hi8 Prototype",
            year: 1986,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 300, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.2, scanLineIntensity: 0.48,
                trackingWobbleSpeed: 0.45, vignetteStrength: 0.28, noiseFloorStrength: 0.22
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 160000,
                hissDb: -42.0, wowFlutterHz: 2.5, wowFlutterDepth: 0.20,
                lowPassCutoffHz: 13000, highPassCutoffHz: 60, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1986 High-Band 8mm",
                year: 1986,
                summary: "Bandwidth expansion to 5.4 MHz delivering 400 lines of horizontal resolution.",
                hardwareHardwareNotes: "Metal Evaporated (ME) tape formulation with high magnetic coercivity.",
                culturalContext: "Broadcast-quality field recordings accessible to consumers."
            )
        ))
        
        // 1987: S-VHS
        list.append(EraModel(
            id: "era_1987_svhs",
            name: "S-VHS",
            year: 1987,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 280, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.1, scanLineIntensity: 0.45,
                trackingWobbleSpeed: 0.40, vignetteStrength: 0.25, noiseFloorStrength: 0.20
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 160000,
                hissDb: -44.0, wowFlutterHz: 2.2, wowFlutterDepth: 0.18,
                lowPassCutoffHz: 14000, highPassCutoffHz: 50, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .vcrOSD, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1987 Super VHS",
                year: 1987,
                summary: "Separate Y/C (S-Video) luminance and chrominance signal path preventing cross-color artifacts.",
                hardwareHardwareNotes: "Carrier frequency shift to 7.0 MHz for over 400 lines resolution.",
                culturalContext: "The weapon of choice for semi-pro wedding videographers."
            )
        ))
        
        // 1988: VHS Camcorder (FREE TIER ICONIC)
        list.append(EraModel(
            id: "era_1988_vhs",
            name: "VHS Camcorder",
            year: 1988,
            category: .camcorderGoldenAge,
            isFree: true, // Free Tier
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 400, whiteBalanceKelvin: 5200,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 2.4, scanLineIntensity: 0.75,
                trackingWobbleSpeed: 0.95, vignetteStrength: 0.42, noiseFloorStrength: 0.40
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -36.0, wowFlutterHz: 5.0, wowFlutterDepth: 0.50,
                lowPassCutoffHz: 10000, highPassCutoffHz: 100, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed, .scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1988 Full-Size VHS Camcorder",
                year: 1988,
                summary: "The definitive nostalgic home video look. Interlaced scanlines, chroma bleeding, cyan clock, and mechanical motor hum.",
                hardwareHardwareNotes: "Solid-state CCD sensor with analog line buffer and composite NTSC encoder.",
                culturalContext: "Captured every iconic 80s birthday party, road trip, and Christmas morning."
            )
        ))
        
        // 1989: Video8 Handycam
        list.append(EraModel(
            id: "era_1989_video8_handycam",
            name: "Video8 Handycam",
            year: 1989,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 320, whiteBalanceKelvin: 5350,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.5, scanLineIntensity: 0.55,
                trackingWobbleSpeed: 0.60, vignetteStrength: 0.30, noiseFloorStrength: 0.28
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 128000,
                hissDb: -40.0, wowFlutterHz: 3.2, wowFlutterDepth: 0.28,
                lowPassCutoffHz: 11000, highPassCutoffHz: 80, bitDepth: 14,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1989 Sony Handycam CCD-TR55",
                year: 1989,
                summary: "The ultra-compact 'passport size' camcorder that revolutionized travel recording.",
                hardwareHardwareNotes: "Single CCD 250k pixel sensor with electronic shutter.",
                culturalContext: "Allowed one-handed spontaneous recording anywhere in the world."
            )
        ))
        
        // 1990: Hi8 Handycam
        list.append(EraModel(
            id: "era_1990_hi8_handycam",
            name: "Hi8 Handycam",
            year: 1990,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 280, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.1, scanLineIntensity: 0.45,
                trackingWobbleSpeed: 0.42, vignetteStrength: 0.26, noiseFloorStrength: 0.20
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 160000,
                hissDb: -44.0, wowFlutterHz: 2.2, wowFlutterDepth: 0.18,
                lowPassCutoffHz: 14000, highPassCutoffHz: 50, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1990 Hi8 Stereo Handycam",
                year: 1990,
                summary: "High-resolution analog tape paired with stereo AFM audio recording.",
                hardwareHardwareNotes: "Dual-head stereo drum with high signal-to-noise ratio.",
                culturalContext: "The quintessential early 90s skate video and indie film medium."
            )
        ))
        
        // 1991: VHS-C Compact
        list.append(EraModel(
            id: "era_1991_vhsc_compact",
            name: "VHS-C Compact",
            year: 1991,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 380, whiteBalanceKelvin: 5250,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 2.0, scanLineIntensity: 0.65,
                trackingWobbleSpeed: 0.82, vignetteStrength: 0.36, noiseFloorStrength: 0.34
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 96000,
                hissDb: -37.0, wowFlutterHz: 4.2, wowFlutterDepth: 0.42,
                lowPassCutoffHz: 9500, highPassCutoffHz: 100, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .vcrOSD, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed, .scanLines]
            ),
            history: EraHistoricalInfo(
                title: "1991 Panasonic Palmcorder",
                year: 1991,
                summary: "Miniaturized VHS-C camcorder with digital electronic image stabilization.",
                hardwareHardwareNotes: "EIS optical gyro sensor with dynamic pixel shift.",
                culturalContext: "Filled living room cabinets with labeled cassette tapes."
            )
        ))
        
        // 1992: S-VHS-C
        list.append(EraModel(
            id: "era_1992_svhsc",
            name: "S-VHS-C",
            year: 1992,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 300, whiteBalanceKelvin: 5350,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.3, scanLineIntensity: 0.48,
                trackingWobbleSpeed: 0.45, vignetteStrength: 0.28, noiseFloorStrength: 0.22
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 160000,
                hissDb: -42.0, wowFlutterHz: 2.6, wowFlutterDepth: 0.22,
                lowPassCutoffHz: 13500, highPassCutoffHz: 60, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#00FFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1992 JVC S-VHS-C Pro",
                year: 1992,
                summary: "Super VHS resolution in compact cassette format.",
                hardwareHardwareNotes: "High-density cobalt-doped iron oxide tape formulation.",
                culturalContext: "Favored for television field interviews and sports highlights."
            )
        ))
        
        // 1993: 8mm Camcorder
        list.append(EraModel(
            id: "era_1993_8mm",
            name: "8mm Camcorder",
            year: 1993,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 320, whiteBalanceKelvin: 5300,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.4, scanLineIntensity: 0.52,
                trackingWobbleSpeed: 0.55, vignetteStrength: 0.30, noiseFloorStrength: 0.25
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 128000,
                hissDb: -40.0, wowFlutterHz: 3.0, wowFlutterDepth: 0.25,
                lowPassCutoffHz: 12000, highPassCutoffHz: 75, bitDepth: 14,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace, .chromaBleed]
            ),
            history: EraHistoricalInfo(
                title: "1993 Consumer 8mm Handycam",
                year: 1993,
                summary: "Warm, filmic color response with gentle organic tape noise.",
                hardwareHardwareNotes: "Infrared NightShot predecessor and motorized optical zoom.",
                culturalContext: "Recorded 90s youth culture, garage bands, and high school graduations."
            )
        ))
        
        // 1994: Hi8 XR
        list.append(EraModel(
            id: "era_1994_hi8_xr",
            name: "Hi8 XR",
            year: 1994,
            category: .camcorderGoldenAge,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "ntsc", shaderFunction: "camcorder_vhs_fragment",
                autoExposureLock: true, fixedISO: 260, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 1.0, scanLineIntensity: 0.40,
                trackingWobbleSpeed: 0.35, vignetteStrength: 0.22, noiseFloorStrength: 0.18
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 160000,
                hissDb: -45.0, wowFlutterHz: 2.0, wowFlutterDepth: 0.15,
                lowPassCutoffHz: 15000, highPassCutoffHz: 40, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy h:mm a", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "1994 Hi8 Extended Resolution (XR)",
                year: 1994,
                summary: "The pinnacle of analog tape engineering before the digital revolution.",
                hardwareHardwareNotes: "440 lines horizontal resolution with digital comb filter.",
                culturalContext: "Peak analog quality before DV arrived."
            )
        ))
        
        // -------------------------------------------------------------
        // CATEGORY 3: EARLY DIGITAL (1995–2004) - 10 Eras
        // -------------------------------------------------------------
        
        // 1995: MiniDV
        list.append(EraModel(
            id: "era_1995_minidv",
            name: "MiniDV",
            year: 1995,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "rec601", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 200, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.6, scanLineIntensity: 0.20,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.18, noiseFloorStrength: 0.15
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 1536000,
                hissDb: -55.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "00:mm:ss:ff", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "1995 MiniDV Digital Cassette",
                year: 1995,
                summary: "Digital component video compression (DV25) with 5:1 DCT compression and uncompressed PCM audio.",
                hardwareHardwareNotes: "FireWire (IEEE 1394) zero-loss digital transfer at 25 Mbps.",
                culturalContext: "Empowered indie filmmakers (The Blair Witch Project) and revolutionized cinema."
            )
        ))
        
        // 1996: Digital8
        list.append(EraModel(
            id: "era_1996_digital8",
            name: "Digital8",
            year: 1996,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "rec601", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 220, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.7, scanLineIntensity: 0.22,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.20, noiseFloorStrength: 0.16
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 1536000,
                hissDb: -54.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "1996 Sony Digital8",
                year: 1996,
                summary: "Digital DV codec recorded onto affordable Hi8 magnetic tape shells.",
                hardwareHardwareNotes: "Double-speed tape transport maintaining full 25 Mbps DV bitstream.",
                culturalContext: "Allowed users to transition smoothly from analog 8mm to digital."
            )
        ))
        
        // 1997: DV Camcorder
        list.append(EraModel(
            id: "era_1997_dv_pro",
            name: "DV Camcorder",
            year: 1997,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "rec601", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 180, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.5, scanLineIntensity: 0.15,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.15, noiseFloorStrength: 0.12
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 1536000,
                hissDb: -58.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "00:mm:ss:ff", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "1997 Professional 3-CCD DV",
                year: 1997,
                summary: "Triple-prism CCD sensor system with dedicated Red, Green, and Blue imagers.",
                hardwareHardwareNotes: "Manual zoom rings, XLR audio jacks, and uncompressed component color.",
                culturalContext: "Established early digital desktop video editing with Apple Final Cut Pro."
            )
        ))
        
        // 1998: Early Webcam
        list.append(EraModel(
            id: "era_1998_webcam",
            name: "Early Webcam",
            year: 1998,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 320, resolutionHeight: 240, frameRate: 15, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: true, fixedISO: 800, whiteBalanceKelvin: 4800,
                posterizeColors: 512, macroblockGridSize: 16,
                chromaticAberrationIntensity: 1.2, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.35, noiseFloorStrength: 0.65
            ),
            audio: AudioConfig(
                sampleRate: 8000, channels: 1, bitrate: 64000,
                hissDb: -32.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 4000, highPassCutoffHz: 300, bitDepth: 8,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.macroblockGrid]
            ),
            history: EraHistoricalInfo(
                title: "1998 Connectix QuickCam",
                year: 1998,
                summary: "Grainy 15fps QCIF video connected via parallel port or early USB 1.0.",
                hardwareHardwareNotes: "Low-cost CMOS sensor with heavy fixed-pattern noise in low light.",
                culturalContext: "The era of CU-SeeMe, ICQ, and the dawn of internet live streaming."
            )
        ))
        
        // 1999: USB Webcam
        list.append(EraModel(
            id: "era_1999_usb_webcam",
            name: "USB Webcam",
            year: 1999,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 352, resolutionHeight: 288, frameRate: 15, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 600, whiteBalanceKelvin: 5000,
                posterizeColors: 1024, macroblockGridSize: 16,
                chromaticAberrationIntensity: 1.0, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.30, noiseFloorStrength: 0.50
            ),
            audio: AudioConfig(
                sampleRate: 11025, channels: 1, bitrate: 88000,
                hissDb: -36.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 5500, highPassCutoffHz: 250, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .digital7, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.macroblockGrid]
            ),
            history: EraHistoricalInfo(
                title: "1999 Logitech QuickCam Express",
                year: 1999,
                summary: "CIF resolution USB camera with characteristic motion blur and block compression.",
                hardwareHardwareNotes: "Fixed focus plastic optic lens with software white balance.",
                culturalContext: "Y2K internet video chats and MSN Messenger video calls."
            )
        ))
        
        // 2000: MiniDV Consumer
        list.append(EraModel(
            id: "era_2000_minidv_consumer",
            name: "MiniDV Consumer",
            year: 2000,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "rec601", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 250, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.8, scanLineIntensity: 0.18,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.20, noiseFloorStrength: 0.18
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 1411000,
                hissDb: -52.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 18000, highPassCutoffHz: 30, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "00:mm:ss:ff", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "2000 Millennium Consumer MiniDV",
                year: 2000,
                summary: "Compact flip-out LCD screen camcorder recording pristine digital tape.",
                hardwareHardwareNotes: "2.5 inch color TFT display with internal tape rewinder mechanism.",
                culturalContext: "Turn-of-the-century family memories captured in digital clarity."
            )
        ))
        
        // 2001: Digital8 Handycam
        list.append(EraModel(
            id: "era_2001_digital8_handycam",
            name: "Digital8 Handycam",
            year: 2001,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "rec601", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 220, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.7, scanLineIntensity: 0.16,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.18, noiseFloorStrength: 0.15
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 1536000,
                hissDb: -55.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd yyyy", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "2001 Sony DCR-TRV Digital8",
                year: 2001,
                summary: "NightShot 0-lux infrared recording with Super SteadyShot stabilization.",
                hardwareHardwareNotes: "Infrared LED illuminator with mechanical IR-cut filter removal.",
                culturalContext: "Infamous for paranormal investigation videos and night adventures."
            )
        ))
        
        // 2002: MicroMV
        list.append(EraModel(
            id: "era_2002_micromv",
            name: "MicroMV",
            year: 2002,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 720, resolutionHeight: 480, frameRate: 30, isInterlaced: true,
                colorSpace: "rec601", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 200, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.6, scanLineIntensity: 0.14,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.16, noiseFloorStrength: 0.14
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 256000,
                hissDb: -54.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 18000, highPassCutoffHz: 30, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .digital7, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "00:mm:ss:ff", blinkingRec: true,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.interlace]
            ),
            history: EraHistoricalInfo(
                title: "2002 Sony MicroMV MPEG-2",
                year: 2002,
                summary: "Ultra-miniature tape cassette 70% smaller than MiniDV using MPEG-2 compression.",
                hardwareHardwareNotes: "12 Mbps MPEG-2 variable bitrate with 64kbit memory chip in cassette.",
                culturalContext: "Pocket-sized luxury gadget that foreshadowed tapeless video."
            )
        ))
        
        // 2003: Early Digicam Video
        list.append(EraModel(
            id: "era_2003_digicam",
            name: "Early Digicam Video",
            year: 2003,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 640, resolutionHeight: 480, frameRate: 15, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: true, fixedISO: 400, whiteBalanceKelvin: 5800,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 1.1, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.32, noiseFloorStrength: 0.38
            ),
            audio: AudioConfig(
                sampleRate: 11025, channels: 1, bitrate: 88000,
                hissDb: -42.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 5500, highPassCutoffHz: 150, bitDepth: 8,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .modernClean, colorHex: "#FF8800",
                position: .bottomRight, format: "MM/dd/yyyy h:mm a", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.macroblockGrid]
            ),
            history: EraHistoricalInfo(
                title: "2003 CCD Digicam Motion JPEG",
                year: 2003,
                summary: "VGA 15fps Motion-JPEG with magenta chromatic fringing and rolling CCD noise.",
                hardwareHardwareNotes: "Interline transfer CCD with CompactFlash storage card.",
                culturalContext: "First wave of casual party snapshots and short video clips."
            )
        ))
        
        // 2004: Digicam Video (Sharpened)
        list.append(EraModel(
            id: "era_2004_digicam",
            name: "Digicam Video",
            year: 2004,
            category: .earlyDigital,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 640, resolutionHeight: 480, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 300, whiteBalanceKelvin: 5600,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.8, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.25, noiseFloorStrength: 0.28
            ),
            audio: AudioConfig(
                sampleRate: 22050, channels: 2, bitrate: 176000,
                hissDb: -46.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 11000, highPassCutoffHz: 100, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .modernClean, colorHex: "#FF9900",
                position: .bottomRight, format: "MMM dd, yyyy", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2004 Sony Cyber-shot / Canon PowerShot",
                year: 2004,
                summary: "Full 30fps VGA video with aggressive edge sharpening and digital zoom grain.",
                hardwareHardwareNotes: "SD card / Memory Stick media with MPEG-1/Motion JPEG encoding.",
                culturalContext: "The era of point-and-shoot digital cameras in every teenager's pocket."
            )
        ))
        
        // -------------------------------------------------------------
        // CATEGORY 4: MOBILE & EARLY SMARTPHONE (2005–2014) - 10 Eras
        // -------------------------------------------------------------
        
        // 2005: Feature Phone QCIF
        list.append(EraModel(
            id: "era_2005_qcif",
            name: "Feature Phone Video",
            year: 2005,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 176, resolutionHeight: 144, frameRate: 10, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "mobile_3gp_fragment",
                autoExposureLock: true, fixedISO: 400, whiteBalanceKelvin: 5200,
                posterizeColors: 256, macroblockGridSize: 16,
                chromaticAberrationIntensity: 1.5, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.40, noiseFloorStrength: 0.55
            ),
            audio: AudioConfig(
                sampleRate: 8000, channels: 1, bitrate: 8000,
                hissDb: -30.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 3400, highPassCutoffHz: 300, bitDepth: 8,
                isMuffled: true, amrEmulation: true
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .nokiaMono, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "3gp", videoCodec: "h263", audioCodec: "amr_nb",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.posterization, .macroblockGrid, .amrAudioDownsample, .threeGPReencode]
            ),
            history: EraHistoricalInfo(
                title: "2005 QCIF 3GP Video",
                year: 2005,
                summary: "176x144 resolution at 10 frames per second with heavy color posterization.",
                hardwareHardwareNotes: "H.263 profile 0 video wrapped in 3GPP container for MMS messages.",
                culturalContext: "Transferred between friends over infrared (IrDA) and early Bluetooth."
            )
        ))
        
        // 2006: Feature Phone QVGA
        list.append(EraModel(
            id: "era_2006_qvga",
            name: "Feature Phone QVGA",
            year: 2006,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 320, resolutionHeight: 240, frameRate: 15, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "mobile_3gp_fragment",
                autoExposureLock: true, fixedISO: 350, whiteBalanceKelvin: 5300,
                posterizeColors: 256, macroblockGridSize: 16,
                chromaticAberrationIntensity: 1.2, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.35, noiseFloorStrength: 0.45
            ),
            audio: AudioConfig(
                sampleRate: 8000, channels: 1, bitrate: 12200,
                hissDb: -32.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 3400, highPassCutoffHz: 300, bitDepth: 8,
                isMuffled: true, amrEmulation: true
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .nokiaMono, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "3gp", videoCodec: "h263", audioCodec: "amr_nb",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.posterization, .macroblockGrid, .amrAudioDownsample, .threeGPReencode]
            ),
            history: EraHistoricalInfo(
                title: "2006 Motorola RAZR V3 / Sony Ericsson",
                year: 2006,
                summary: "Quarter VGA resolution video recorded on flip phones and slider handsets.",
                hardwareHardwareNotes: "Early CMOS sensor module with rolling shutter and AMR audio.",
                culturalContext: "Recorded concert bootlegs from the front row before smartphones existed."
            )
        ))
        
        // 2007: Early Smartphone
        list.append(EraModel(
            id: "era_2007_early_smartphone",
            name: "Early Smartphone",
            year: 2007,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 320, resolutionHeight: 240, frameRate: 15, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "mobile_3gp_fragment",
                autoExposureLock: false, fixedISO: 300, whiteBalanceKelvin: 5400,
                posterizeColors: 0, macroblockGridSize: 16,
                chromaticAberrationIntensity: 0.9, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.28, noiseFloorStrength: 0.35
            ),
            audio: AudioConfig(
                sampleRate: 16000, channels: 1, bitrate: 32000,
                hissDb: -40.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 7000, highPassCutoffHz: 200, bitDepth: 12,
                isMuffled: true, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.macroblockGrid]
            ),
            history: EraHistoricalInfo(
                title: "2007 Original iPhone / Symbian Era",
                year: 2007,
                summary: "The emergence of touchscreens and mobile internet video.",
                hardwareHardwareNotes: "2.0 MP fixed-focus camera sensor without video recording (hacked by jailbreakers).",
                culturalContext: "The dawn of the multi-touch mobile computing revolution."
            )
        ))
        
        // 2008: Nokia 3GP (FREE TIER ICONIC)
        list.append(EraModel(
            id: "era_2008_nokia",
            name: "Nokia 3GP",
            year: 2008,
            category: .mobileEarlySmartphone,
            isFree: true, // Free Tier
            video: VideoConfig(
                resolutionWidth: 320, resolutionHeight: 240, frameRate: 15, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "mobile_3gp_fragment",
                autoExposureLock: true, fixedISO: 400, whiteBalanceKelvin: 5100,
                posterizeColors: 256, macroblockGridSize: 16,
                chromaticAberrationIntensity: 1.4, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.38, noiseFloorStrength: 0.50
            ),
            audio: AudioConfig(
                sampleRate: 8000, channels: 1, bitrate: 12200,
                hissDb: -32.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 3400, highPassCutoffHz: 300, bitDepth: 8,
                isMuffled: true, amrEmulation: true
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .nokiaMono, colorHex: "#FFFFFF",
                position: .topRight, format: "Nokia 3GP", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "3gp", videoCodec: "h263", audioCodec: "amr_nb",
                nativeAspectRatio: .standard4_3, pipelineSteps: [.posterization, .macroblockGrid, .amrAudioDownsample, .threeGPReencode]
            ),
            history: EraHistoricalInfo(
                title: "2008 Nokia N95 / 5800 XpressMusic",
                year: 2008,
                summary: "Locked auto-exposure, 256-color posterization, 16x16 macroblock grid, and muffled 12.2kbps AMR audio.",
                hardwareHardwareNotes: "Carl Zeiss optics with mechanical autofocus paired with aggressive H.263 video encoder.",
                culturalContext: "The legendary phone camera that ruled European and Asian mobile video."
            )
        ))
        
        // 2009: iPhone 3GS
        list.append(EraModel(
            id: "era_2009_iphone3gs",
            name: "iPhone 3GS",
            year: 2009,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 640, resolutionHeight: 480, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 250, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 8,
                chromaticAberrationIntensity: 0.7, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.22, noiseFloorStrength: 0.25
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 64000,
                hissDb: -48.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 12000, highPassCutoffHz: 80, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .standard4_3, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2009 iPhone 3GS Video Recording",
                year: 2009,
                summary: "Apple's first official video recording iPhone with tap-to-focus and auto white balance.",
                hardwareHardwareNotes: "3.0 MP OmniVision sensor capturing 30fps VGA with hardware H.264 compression.",
                culturalContext: "Made filming and instant YouTube uploading effortless."
            )
        ))
        
        // 2010: iPhone 4
        list.append(EraModel(
            id: "era_2010_iphone4",
            name: "iPhone 4 720p",
            year: 2010,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 1280, resolutionHeight: 720, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 200, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.5, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.18, noiseFloorStrength: 0.18
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 1, bitrate: 128000,
                hissDb: -52.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 16000, highPassCutoffHz: 60, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2010 iPhone 4 HD 720p",
                year: 2010,
                summary: "Retina display and 720p HD recording with Backside Illuminated (BSI) sensor.",
                hardwareHardwareNotes: "5.0 MP BSI sensor with LED flash and secondary noise-cancelling microphone.",
                culturalContext: "Launched mobile HD video creation into mainstream culture."
            )
        ))
        
        // 2011: Android 720p
        list.append(EraModel(
            id: "era_2011_android",
            name: "Android 720p",
            year: 2011,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 1280, resolutionHeight: 720, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 250, whiteBalanceKelvin: 5600,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.6, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.20, noiseFloorStrength: 0.22
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 128000,
                hissDb: -50.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 15000, highPassCutoffHz: 60, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2011 Samsung Galaxy S II / HTC EVO",
                year: 2011,
                summary: "Vibrant AMOLED saturated colors with aggressive software noise reduction.",
                hardwareHardwareNotes: "8.0 MP sensor with dual-core processor encoding hardware 720p.",
                culturalContext: "The smartphone wars kicked into high gear."
            )
        ))
        
        // 2012: Early Smartphone HDR (FREE TIER ICONIC)
        list.append(EraModel(
            id: "era_2012_early_hdr",
            name: "Early Smartphone HDR",
            year: 2012,
            category: .mobileEarlySmartphone,
            isFree: true, // Free Tier
            video: VideoConfig(
                resolutionWidth: 1280, resolutionHeight: 720, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "early_digital_fragment",
                autoExposureLock: false, fixedISO: 200, whiteBalanceKelvin: 5700,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.5, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.16, noiseFloorStrength: 0.16
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 128000,
                hissDb: -52.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 16000, highPassCutoffHz: 50, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: true, font: .modernClean, colorHex: "#FFFFFF",
                position: .bottomLeft, format: "MMM dd, yyyy", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: true, gpsAllowed: true
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2012 iPhone 5 / Early HDR",
                year: 2012,
                summary: "Oversharpened edge halos, hyper-saturated sky blues, and dynamic range tonemapping.",
                hardwareHardwareNotes: "Sapphire crystal lens cover with hybrid IR filter and 1080p video stabilization.",
                culturalContext: "Instagram added video sharing and Vine launched 6-second looping videos."
            )
        ))
        
        // 2013: iPhone 5s
        list.append(EraModel(
            id: "era_2013_iphone5s",
            name: "iPhone 5s Slow-Mo",
            year: 2013,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 1920, resolutionHeight: 1080, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.3, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.12, noiseFloorStrength: 0.10
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 256000,
                hissDb: -58.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2013 iPhone 5s TrueTone & 120fps",
                year: 2013,
                summary: "64-bit A7 processor enabling 120fps 720p slow-motion capture and dual TrueTone flash.",
                hardwareHardwareNotes: "1.5 micron pixel sensor with f/2.2 aperture and continuous autofocus.",
                culturalContext: "Slow-motion sports clips went viral across all social platforms."
            )
        ))
        
        // 2014: Android 1080p
        list.append(EraModel(
            id: "era_2014_android1080p",
            name: "Android 1080p",
            year: 2014,
            category: .mobileEarlySmartphone,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 1920, resolutionHeight: 1080, frameRate: 30, isInterlaced: false,
                colorSpace: "srgb", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.3, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.12, noiseFloorStrength: 0.10
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 256000,
                hissDb: -58.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2014 Sony Xperia / Samsung Galaxy S5",
                year: 2014,
                summary: "Full 1080p recording with phase detection autofocus and high megapixel counts.",
                hardwareHardwareNotes: "ISOCELL sensor technology reducing pixel-to-pixel crosstalk.",
                culturalContext: "Mobile video rivaled dedicated camcorder image clarity."
            )
        ))
        
        // -------------------------------------------------------------
        // CATEGORY 5: MODERN SMARTPHONE REFERENCE (2015–2026) - 12 Eras
        // -------------------------------------------------------------
        
        // 2015: iPhone 6s 4K
        list.append(EraModel(
            id: "era_2015_iphone6s",
            name: "iPhone 6s 4K",
            year: 2015,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 30, isInterlaced: false,
                colorSpace: "rec709", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.1, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.08, noiseFloorStrength: 0.06
            ),
            audio: AudioConfig(
                sampleRate: 44100, channels: 2, bitrate: 256000,
                hissDb: -60.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "h264", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2015 iPhone 6s 4K Resolution",
                year: 2015,
                summary: "First 4K (3840x2160) ultra-high-definition capture on iPhone at 30fps.",
                hardwareHardwareNotes: "12 MP sensor with deep trench isolation and Live Photos.",
                culturalContext: "Set the 4K standard for desktop monitors and 4K televisions."
            )
        ))
        
        // 2016: Smartphone 4K
        list.append(EraModel(
            id: "era_2016_4k",
            name: "Smartphone 4K",
            year: 2016,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 30, isInterlaced: false,
                colorSpace: "rec709", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.1, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.08, noiseFloorStrength: 0.05
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 256000,
                hissDb: -62.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 20000, highPassCutoffHz: 20, bitDepth: 16,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2016 Dual-Camera Systems",
                year: 2016,
                summary: "Dual lens optical zoom with Portrait mode bokeh simulation.",
                hardwareHardwareNotes: "Wide + Telephoto optical pairing with HEVC compression.",
                culturalContext: "Computational photography emerged as a major differentiator."
            )
        ))
        
        // 2017: iPhone X HDR
        list.append(EraModel(
            id: "era_2017_iphonex",
            name: "iPhone X 4K HDR",
            year: 2017,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "p3", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.05, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.05, noiseFloorStrength: 0.04
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 320000,
                hissDb: -65.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2017 iPhone X OLED & 4K60",
                year: 2017,
                summary: "Smooth 60fps 4K capture with Display P3 wide color gamut and TrueDepth front camera.",
                hardwareHardwareNotes: "Optical Image Stabilization on both wide and telephoto lenses.",
                culturalContext: "Redefined smartphone industrial design with bezel-less displays."
            )
        ))
        
        // 2018: Smartphone 4K60
        list.append(EraModel(
            id: "era_2018_4k60",
            name: "Smartphone 4K60",
            year: 2018,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "p3", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.05, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.05, noiseFloorStrength: 0.04
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 320000,
                hissDb: -66.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2018 Smart HDR Capture",
                year: 2018,
                summary: "Multi-frame exposure fusion blending underexposed and overexposed frames instantaneously.",
                hardwareHardwareNotes: "Neural Engine dedicated silicon for real-time video tone mapping.",
                culturalContext: "Preserved highlight detail in direct sunlight seamlessly."
            )
        ))
        
        // 2019: iPhone 11 Night Video
        list.append(EraModel(
            id: "era_2019_night_video",
            name: "iPhone 11 Night Video",
            year: 2019,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "p3", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 100, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.04, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.04, noiseFloorStrength: 0.03
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 320000,
                hissDb: -68.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2019 Ultra-Wide & Night Mode",
                year: 2019,
                summary: "Triple-camera array with 120-degree Ultra-Wide field of view and Audio Zoom tracking.",
                hardwareHardwareNotes: "100% Focus Pixels sensor with continuous temporal noise filtering.",
                culturalContext: "Short-form TikTok content creation exploded globally."
            )
        ))
        
        // 2020: iPhone 12 Dolby Vision
        list.append(EraModel(
            id: "era_2020_dolby_vision",
            name: "iPhone 12 Dolby Vision",
            year: 2020,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "rec2020_hlg", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 80, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.03, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.03, noiseFloorStrength: 0.02
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -70.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2020 10-Bit Dolby Vision HDR",
                year: 2020,
                summary: "First smartphone to record, edit, and play back 10-bit Dolby Vision HDR video directly in real time.",
                hardwareHardwareNotes: "Sensor-shift optical stabilization and LiDAR scanner depth mapping.",
                culturalContext: "Hollywood cinema-grade color reproduction in a pocket device."
            )
        ))
        
        // 2021: iPhone 13 Cinematic
        list.append(EraModel(
            id: "era_2021_cinematic",
            name: "iPhone 13 Cinematic Mode",
            year: 2021,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 30, isInterlaced: false,
                colorSpace: "rec2020_hlg", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 64, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.02, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.02, noiseFloorStrength: 0.02
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -72.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2021 Cinematic Mode & Rack Focus",
                year: 2021,
                summary: "Automated depth-of-field transition between subjects with real-time neural gaze detection.",
                hardwareHardwareNotes: "Larger 1.9µm pixels sensor with ProRes video recording support.",
                culturalContext: "Brought rack focus techniques from cinema cameras to amateur creators."
            )
        ))
        
        // 2022: iPhone 14 Action Mode
        list.append(EraModel(
            id: "era_2022_action_mode",
            name: "iPhone 14 Action Mode",
            year: 2022,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "rec2020_hlg", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 50, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.02, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.02, noiseFloorStrength: 0.01
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -74.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2022 48MP Photonic Engine & Action Mode",
                year: 2022,
                summary: "Gimbal-like extreme motion stabilization with 2.8K oversampling and 48MP quad-pixel sensor.",
                hardwareHardwareNotes: "Second-generation sensor-shift stabilization with Photonic Engine pipeline.",
                culturalContext: "Replaced dedicated action cameras for running and extreme sports."
            )
        ))
        
        // 2023: iPhone 15 Pro ProRes Log
        list.append(EraModel(
            id: "era_2023_prores_log",
            name: "iPhone 15 Pro Log",
            year: 2023,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "apple_log", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 50, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.01, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.01, noiseFloorStrength: 0.01
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -75.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 22000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mov", videoCodec: "prores", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2023 Apple Log & External SSD Recording",
                year: 2023,
                summary: "Flat log curve encoding ACES color space directly to external USB-C drives.",
                hardwareHardwareNotes: "Titanium chassis with USB 3.0 10Gbps data throughput and 4K60 ProRes Log.",
                culturalContext: "Used by professional Hollywood DPs to shoot full feature films."
            )
        ))
        
        // 2024: iPhone 16 Pro 4K120
        list.append(EraModel(
            id: "era_2024_4k120",
            name: "iPhone 16 Pro 4K120",
            year: 2024,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 120, isInterlaced: false,
                colorSpace: "rec2020_hlg", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 50, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.0, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.0, noiseFloorStrength: 0.005
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -78.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 24000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mov", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2024 4K120fps Dolby Vision & Camera Control",
                year: 2024,
                summary: "Extreme slow-motion in 4K resolution with dedicated capacitive sapphire Camera Control button.",
                hardwareHardwareNotes: "48MP Fusion sensor with 2x faster sensor readout eliminating rolling shutter.",
                culturalContext: "Studio-quality frame rates and instant tactile hardware capture."
            )
        ))
        
        // 2025: iPhone 17 Pro
        list.append(EraModel(
            id: "era_2025_iphone17",
            name: "iPhone 17 Pro",
            year: 2025,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "rec2020_hlg", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 50, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.0, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.0, noiseFloorStrength: 0.005
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -80.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 24000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2025 Neural Spatial Video",
                year: 2025,
                summary: "Spatial 3D stereoscopic video captured for Vision Pro immersive playback.",
                hardwareHardwareNotes: "Triple 48MP sensor array with optical periscope telephoto.",
                culturalContext: "Bridging the gap between 2D flat video and 3D spatial memory capture."
            )
        ))
        
        // 2026: iPhone 17 Pro Max (Modern Reference Baseline)
        list.append(EraModel(
            id: "era_2026_modern_reference",
            name: "iPhone 17 Pro Max",
            year: 2026,
            category: .modernReference,
            isFree: false,
            video: VideoConfig(
                resolutionWidth: 3840, resolutionHeight: 2160, frameRate: 60, isInterlaced: false,
                colorSpace: "rec2020_hlg", shaderFunction: "modern_reference_fragment",
                autoExposureLock: false, fixedISO: 50, whiteBalanceKelvin: 5500,
                posterizeColors: 0, macroblockGridSize: 0,
                chromaticAberrationIntensity: 0.0, scanLineIntensity: 0.0,
                trackingWobbleSpeed: 0.0, vignetteStrength: 0.0, noiseFloorStrength: 0.0
            ),
            audio: AudioConfig(
                sampleRate: 48000, channels: 2, bitrate: 384000,
                hissDb: -80.0, wowFlutterHz: 0.0, wowFlutterDepth: 0.0,
                lowPassCutoffHz: 24000, highPassCutoffHz: 20, bitDepth: 24,
                isMuffled: false, amrEmulation: false
            ),
            dateStamp: DateStampConfig(
                enabled: false, font: .modernClean, colorHex: "#FFFFFF",
                position: .none, format: "", blinkingRec: false,
                recDotColorHex: "#FF0000", customTextAllowed: false, gpsAllowed: false
            ),
            export: ExportConfig(
                container: "mp4", videoCodec: "hevc", audioCodec: "aac",
                nativeAspectRatio: .widescreen16_9, pipelineSteps: []
            ),
            history: EraHistoricalInfo(
                title: "2026 Modern Reference Baseline",
                year: 2026,
                summary: "The unadulterated baseline camera feed against which historical degradation is measured.",
                hardwareHardwareNotes: "Next-generation Apple Silicon neural computational imaging pipeline.",
                culturalContext: "The reference pinnacle of contemporary mobile imaging."
            )
        ))
        
        return list
    }
}
