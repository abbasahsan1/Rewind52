//
//  DateStampRenderer.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import UIKit
import Metal
import CoreGraphics

public final class DateStampRenderer: @unchecked Sendable {
    private let device: MTLDevice
    private let dateFormatter = DateFormatter()
    private var cachedTexture: MTLTexture?
    private var lastRenderSecond: Int = -1
    private var lastBlinkState: Bool = false
    
    public init(device: MTLDevice) {
        self.device = device
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }
    
    /// Generates a transparent overlay MTLTexture containing authentic date stamp, blinking REC dot, and era HUD.
    public func renderOverlayTexture(
        era: EraModel,
        state: OSDState,
        size: CGSize
    ) -> MTLTexture? {
        guard era.dateStamp.enabled || state.isRecording else {
            return nil
        }
        
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }
        
        // 1. Calculate 1Hz square wave for blinking REC dot
        let blinkOn = (Int(CACurrentMediaTime() * 2.0) % 2) == 0
        
        // Format Date text
        let displayDate = state.customDate ?? Date()
        let format = era.dateStamp.format.isEmpty ? "MMM dd yyyy" : era.dateStamp.format
        dateFormatter.dateFormat = format
        let dateString: String
        if let customText = state.customText, !customText.isEmpty, era.dateStamp.customTextAllowed {
            dateString = customText.uppercased()
        } else {
            dateString = dateFormatter.string(from: displayDate).uppercased()
        }
        
        // 2. Setup CoreGraphics bitmap context
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }
        
        // Clear background to fully transparent
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        
        UIGraphicsPushContext(context)
        
        // 3. Draw Blinking REC Dot & "REC" text at top-left/top-right if recording
        if state.isRecording && era.dateStamp.blinkingRec {
            let recDotRadius: CGFloat = CGFloat(height) * 0.016
            let recMargin: CGFloat = CGFloat(width) * 0.05
            let recY: CGFloat = CGFloat(height) * 0.90
            
            if blinkOn {
                // Red Dot
                context.setFillColor(UIColor.red.cgColor)
                context.fillEllipse(in: CGRect(x: recMargin, y: recY - recDotRadius, width: recDotRadius * 2, height: recDotRadius * 2))
                
                // "REC" text
                let recFont = UIFont.monospacedDigitSystemFont(ofSize: recDotRadius * 1.8, weight: .black)
                let recAttrs: [NSAttributedString.Key: Any] = [
                    .font: recFont,
                    .foregroundColor: UIColor.red,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -3.0
                ]
                let recText = "REC" as NSString
                recText.draw(at: CGPoint(x: recMargin + recDotRadius * 2.6, y: recY - recDotRadius * 0.9), withAttributes: recAttrs)
            }
            
            // Tape duration counter: e.g. "SP 0:02:45"
            let durationSeconds = Int(state.recordingDuration)
            let mins = durationSeconds / 60
            let secs = durationSeconds % 60
            let timeStr = String(format: "SP %02d:%02d", mins, secs) as NSString
            let timeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: recDotRadius * 1.6, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0
            ]
            timeStr.draw(at: CGPoint(x: CGFloat(width) - CGFloat(width) * 0.28, y: recY - recDotRadius * 0.9), withAttributes: timeAttrs)
        }
        
        // 4. Draw Date Stamp
        if era.dateStamp.enabled {
            let fontSize: CGFloat = CGFloat(height) * 0.038
            let textColor = UIColor(hex: era.dateStamp.colorHex) ?? .cyan
            
            let font: UIFont
            switch era.dateStamp.font {
            case .digital7, .vcrOSD:
                font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .heavy)
            case .nokiaMono:
                font = UIFont.monospacedDigitSystemFont(ofSize: fontSize * 0.85, weight: .bold)
            case .modernClean:
                font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            case .typewriter:
                font = UIFont(name: "Courier-Bold", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
            }
            
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .strokeColor: UIColor.black.withAlphaComponent(0.85),
                .strokeWidth: -4.0
            ]
            
            let nsDateString = dateString as NSString
            let textSize = nsDateString.size(withAttributes: textAttrs)
            
            let posX: CGFloat
            let posY: CGFloat
            let marginX: CGFloat = CGFloat(width) * 0.05
            let marginY: CGFloat = CGFloat(height) * 0.06
            
            switch era.dateStamp.position {
            case .bottomLeft:
                posX = marginX
                posY = marginY
            case .bottomRight:
                posX = CGFloat(width) - textSize.width - marginX
                posY = marginY
            case .topLeft:
                posX = marginX
                posY = CGFloat(height) - textSize.height - marginY
            case .topRight:
                posX = CGFloat(width) - textSize.width - marginX
                posY = CGFloat(height) - textSize.height - marginY
            case .centerBottom:
                posX = (CGFloat(width) - textSize.width) / 2.0
                posY = marginY
            case .none:
                posX = -1000
                posY = -1000
            }
            
            if posX > 0 && posY > 0 {
                nsDateString.draw(at: CGPoint(x: posX, y: posY), withAttributes: textAttrs)
            }
            
            // 5. Draw Nokia 3GP Status HUD (Battery + Signal + "Options" menu)
            if era.id == "era_2008_nokia" || state.showBatteryAndSignal {
                let nokiaFont = UIFont.monospacedDigitSystemFont(ofSize: fontSize * 0.7, weight: .bold)
                let nokiaAttrs: [NSAttributedString.Key: Any] = [
                    .font: nokiaFont,
                    .foregroundColor: UIColor.white,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -3.0
                ]
                
                let signalStr = "|||| 3G" as NSString
                signalStr.draw(at: CGPoint(x: marginX, y: CGFloat(height) - marginY * 1.5), withAttributes: nokiaAttrs)
                
                let battStr = "[||||]" as NSString
                battStr.draw(at: CGPoint(x: CGFloat(width) - marginX - 50, y: CGFloat(height) - marginY * 1.5), withAttributes: nokiaAttrs)
                
                let bottomMenu = "Options                 Exit" as NSString
                bottomMenu.draw(at: CGPoint(x: marginX, y: marginY * 0.3), withAttributes: nokiaAttrs)
            }
            
            // 6. Draw GPS Coordinates Spoofing if enabled
            if let gps = state.fakeGPSCoordinates, era.dateStamp.gpsAllowed {
                let gpsFont = UIFont.monospacedSystemFont(ofSize: fontSize * 0.65, weight: .medium)
                let gpsAttrs: [NSAttributedString.Key: Any] = [
                    .font: gpsFont,
                    .foregroundColor: textColor.withAlphaComponent(0.9),
                    .strokeColor: UIColor.black,
                    .strokeWidth: -2.5
                ]
                let gpsStr = gps as NSString
                gpsStr.draw(at: CGPoint(x: posX, y: posY + textSize.height + 4), withAttributes: gpsAttrs)
            }
        }
        
        UIGraphicsPopContext()
        
        // 7. Create MTLTexture from context raw pixel data
        guard let pixelData = context.data else { return nil }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixelData, bytesPerRow: bytesPerRow)
        
        return texture
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: CGFloat
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
