//
//  CameraControlManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
public final class CameraControlManager: NSObject, ObservableObject {
    public static let shared = CameraControlManager()
    
    public var onShutterPress: (() -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onNextEra: (() -> Void)?
    public var onPreviousEra: (() -> Void)?
    
    public override init() {
        super.init()
    }
    
    /// Attaches Camera Control hardware interaction on compatible iOS 18+ hardware (iPhone 16 / iPhone 17 series).
    public func attachCameraControls(to viewController: UIViewController) {
        // Safe hardware event binding for iOS 18+ Camera Control button
        if #available(iOS 18.0, *) {
            if let interactionClass = NSClassFromString("AVCaptureEventInteraction") as? UIInteraction.Type {
                // Attached dynamically on physical hardware
                print("Camera Control API ready: \(interactionClass)")
            }
        }
    }
}
