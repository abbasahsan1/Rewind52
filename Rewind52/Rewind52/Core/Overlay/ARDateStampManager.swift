//
//  ARDateStampManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import ARKit
import UIKit
import SceneKit
import Combine

@MainActor
public final class ARDateStampManager: NSObject, ARSessionDelegate, ObservableObject {
    public static let shared = ARDateStampManager()
    
    @Published public var isARActive: Bool = false
    @Published public var dateStampWorldPosition: simd_float3?
    @Published public var projectedScreenPoint: CGPoint?
    
    private var arSession: ARSession?
    
    public override init() {
        super.init()
    }
    
    public var isSupported: Bool {
        ARWorldTrackingConfiguration.isSupported
    }
    
    public func startARSession() {
        guard isSupported else { return }
        
        let session = ARSession()
        session.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.arSession = session
        self.isARActive = true
    }
    
    public func stopARSession() {
        arSession?.pause()
        arSession = nil
        isARActive = false
        projectedScreenPoint = nil
    }
    
    public func setAnchorAtCenter(viewSize: CGSize) {
        guard let session = arSession, let currentFrame = session.currentFrame else { return }
        
        // Place virtual anchor 0.6 meters in front of the camera
        let cameraTransform = currentFrame.camera.transform
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.6 // 60cm forward
        translation.columns.3.y = -0.1 // 10cm lower
        
        let worldTransform = matrix_multiply(cameraTransform, translation)
        let worldPos = simd_make_float3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
        self.dateStampWorldPosition = worldPos
    }
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let worldPos = dateStampWorldPosition else { return }
        
        // Project 3D world position to 2D normalized viewport
        let camera = frame.camera
        let projected = camera.projectPoint(worldPos, orientation: .portrait, viewportSize: CGSize(width: 1080, height: 1920))
        
        Task { @MainActor in
            self.projectedScreenPoint = projected
        }
    }
}
