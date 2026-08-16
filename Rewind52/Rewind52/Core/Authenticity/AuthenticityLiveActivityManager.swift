//
//  AuthenticityLiveActivityManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import Combine
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
public struct AuthenticityActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var progress: Double
        public var statusMessage: String
        public var eraTitle: String
        
        public init(progress: Double, statusMessage: String, eraTitle: String) {
            self.progress = progress
            self.statusMessage = statusMessage
            self.eraTitle = eraTitle
        }
    }
    
    public var eraName: String
    
    public init(eraName: String) {
        self.eraName = eraName
    }
}
#endif

@MainActor
public final class AuthenticityLiveActivityManager: ObservableObject {
    public static let shared = AuthenticityLiveActivityManager()
    
    @Published public var currentProgress: Double = 0.0
    @Published public var currentStatus: String = ""
    
    #if canImport(ActivityKit)
    private var currentActivity: Any? // Activity<AuthenticityActivityAttributes>?
    #endif
    
    private init() {}
    
    public func startActivity(eraName: String) {
        currentProgress = 0.0
        currentStatus = "Starting Authenticity Pipeline..."
        
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let attributes = AuthenticityActivityAttributes(eraName: eraName)
            let initialState = AuthenticityActivityAttributes.ContentState(
                progress: 0.0,
                statusMessage: "Crunching to 320x240 low-bitrate...",
                eraTitle: eraName
            )
            do {
                let activity = try Activity<AuthenticityActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: initialState, staleDate: nil)
                )
                self.currentActivity = activity
            } catch {
                print("Live Activity request failed: \(error)")
            }
        }
        #endif
    }
    
    public func updateProgress(progress: Double, status: String, eraName: String) {
        self.currentProgress = progress
        self.currentStatus = status
        
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *), let activity = currentActivity as? Activity<AuthenticityActivityAttributes> {
            let updatedState = AuthenticityActivityAttributes.ContentState(
                progress: progress,
                statusMessage: status,
                eraTitle: eraName
            )
            Task {
                await activity.update(.init(state: updatedState, staleDate: nil))
            }
        }
        #endif
    }
    
    public func endActivity(finalStatus: String) {
        self.currentProgress = 1.0
        self.currentStatus = finalStatus
        
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *), let activity = currentActivity as? Activity<AuthenticityActivityAttributes> {
            Task {
                await activity.end(dismissalPolicy: .immediate)
                self.currentActivity = nil
            }
        }
        #endif
    }
}
