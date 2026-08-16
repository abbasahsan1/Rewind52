//
//  EntitlementManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class EntitlementManager: ObservableObject {
    public static let shared = EntitlementManager()
    
    @Published public var isPro: Bool = false
    @Published public var unlockedEraIDs: Set<String> = []
    
    private let userDefaultsKeyPro = "com.rewind52.entitlements.isPro"
    private let userDefaultsKeyEras = "com.rewind52.entitlements.unlockedEras"
    
    public init() {
        self.isPro = UserDefaults.standard.bool(forKey: userDefaultsKeyPro)
        if let savedEras = UserDefaults.standard.stringArray(forKey: userDefaultsKeyEras) {
            self.unlockedEraIDs = Set(savedEras)
        }
    }
    
    public func canAccessEra(_ era: EraModel) -> Bool {
        if era.isFree { return true }
        if isPro { return true }
        return unlockedEraIDs.contains(era.id)
    }
    
    public var shouldShowWatermark: Bool {
        !isPro
    }
    
    public var maxRecordingDuration: TimeInterval {
        isPro ? .infinity : 60.0
    }
    
    public var canUseMultiCam: Bool {
        isPro
    }
    
    public var canUseARDateStamp: Bool {
        isPro
    }
    
    public var canUseCustomText: Bool {
        isPro
    }
    
    public func unlockPro() {
        self.isPro = true
        UserDefaults.standard.set(true, forKey: userDefaultsKeyPro)
    }
    
    public func unlockEra(id: String) {
        self.unlockedEraIDs.insert(id)
        UserDefaults.standard.set(Array(unlockedEraIDs), forKey: userDefaultsKeyEras)
    }
    
    public func resetEntitlements() {
        self.isPro = false
        self.unlockedEraIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyPro)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeyEras)
    }
}
