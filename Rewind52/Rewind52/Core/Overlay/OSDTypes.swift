//
//  OSDTypes.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import CoreGraphics
import UIKit

public struct OSDState: Sendable {
    public var customDate: Date?
    public var customText: String?
    public var isRecording: Bool
    public var recordingDuration: TimeInterval
    public var showBatteryAndSignal: Bool
    public var fakeGPSCoordinates: String?
    
    public init(
        customDate: Date? = nil,
        customText: String? = nil,
        isRecording: Bool = false,
        recordingDuration: TimeInterval = 0,
        showBatteryAndSignal: Bool = false,
        fakeGPSCoordinates: String? = nil
    ) {
        self.customDate = customDate
        self.customText = customText
        self.isRecording = isRecording
        self.recordingDuration = recordingDuration
        self.showBatteryAndSignal = showBatteryAndSignal
        self.fakeGPSCoordinates = fakeGPSCoordinates
    }
}
