//
//  CameraService.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreVideo
import UIKit
import Combine

public protocol CameraServiceDelegate: AnyObject, Sendable {
    func cameraService(_ service: CameraService, didOutput pixelBuffer: CVPixelBuffer, presentationTime: CMTime)
}

@MainActor
public final class CameraService: NSObject, ObservableObject {
    public static let shared = CameraService()
    
    @Published public var isSessionRunning: Bool = false
    @Published public var currentPosition: AVCaptureDevice.Position = .back
    @Published public var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published public var isTorchOn: Bool = false
    @Published public var zoomFactor: CGFloat = 1.0
    @Published public var minZoomFactor: CGFloat = 1.0
    @Published public var maxZoomFactor: CGFloat = 10.0
    @Published public var hasMultipleCameras: Bool = false
    @Published public var isMultiCamSupported: Bool = false
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.rewind52.camera.sessionQueue", qos: .userInitiated)
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let frameDelegateLock = NSLock()
    nonisolated(unsafe) public weak var delegate: CameraServiceDelegate?
    
    nonisolated(unsafe) private var targetFrameRate: Int = 30
    nonisolated(unsafe) private var lastEmittedFrameTime: TimeInterval = 0
    private var lockAutoExposure: Bool = false
    
    public override init() {
        super.init()
        self.isMultiCamSupported = AVCaptureMultiCamSession.isMultiCamSupported
    }
    
    public func configure() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { return }
        } else if status != .authorized {
            return
        }
        
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Discover primary back camera
        guard let device = selectCaptureDevice(for: .back) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                self.videoDeviceInput = input
            }
            
            // Configure Video Data Output for 32BGRA frames
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            // Configure portrait video orientation
            if let connection = videoDataOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
            Task { @MainActor in
                self.isSessionRunning = self.captureSession.isRunning
                self.updateZoomConstraints()
            }
        } catch {
            captureSession.commitConfiguration()
            print("Error configuring camera session: \(error)")
        }
    }
    
    public func start() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            Task { @MainActor in
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }
    
    public func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }
    
    public func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let newPosition: AVCaptureDevice.Position = (self.currentPosition == .back) ? .front : .back
            guard let newDevice = self.selectCaptureDevice(for: newPosition) else { return }
            
            self.captureSession.beginConfiguration()
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDeviceInput = newInput
                }
                
                // Fix orientation for new connection
                if let connection = self.videoDataOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                    if newPosition == .front && connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
                
                self.captureSession.commitConfiguration()
                
                Task { @MainActor in
                    self.currentPosition = newPosition
                    self.zoomFactor = 1.0
                    self.updateZoomConstraints()
                }
            } catch {
                self.captureSession.commitConfiguration()
                print("Failed to switch camera: \(error)")
            }
        }
    }
    
    public func setZoom(_ factor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        let clamped = max(minZoomFactor, min(factor, maxZoomFactor))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            self.zoomFactor = clamped
        } catch {
            print("Failed to set video zoom: \(error)")
        }
    }
    
    public func toggleTorch() {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                self.isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                self.isTorchOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to toggle torch: \(error)")
        }
    }
    
    public func setEraConfiguration(_ era: EraModel) {
        self.targetFrameRate = era.video.frameRate
        self.lockAutoExposure = era.video.autoExposureLock
        
        guard let device = videoDeviceInput?.device else { return }
        do {
            try device.lockForConfiguration()
            if era.video.autoExposureLock && device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            } else if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to apply era camera hardware config: \(error)")
        }
    }
    
    private func updateZoomConstraints() {
        guard let device = videoDeviceInput?.device else { return }
        self.minZoomFactor = device.minAvailableVideoZoomFactor
        self.maxZoomFactor = min(device.maxAvailableVideoZoomFactor, 10.0)
    }
    
    private func selectCaptureDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        return discovery.devices.first ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Era Hardware Throttling: e.g. 10fps or 15fps for Nokia/Webcams
        let now = CACurrentMediaTime()
        let minFrameInterval = 1.0 / Double(max(1, targetFrameRate))
        
        if now - lastEmittedFrameTime >= minFrameInterval * 0.92 {
            self.lastEmittedFrameTime = now
            self.delegate?.cameraService(self, didOutput: pixelBuffer, presentationTime: presentationTime)
        }
    }
}
