//
//  CameraService.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreVideo
import CoreMedia
import UIKit
import Combine

public protocol CameraServiceDelegate: AnyObject, Sendable {
    func cameraService(_ service: CameraService, didOutput pixelBuffer: CVPixelBuffer, presentationTime: CMTime)
}

public enum CameraLensType: String, CaseIterable, Identifiable, Sendable {
    case ultraWide = "0.5x"
    case wide = "1x"
    case telephoto = "3x"
    
    public var id: String { rawValue }
}

public enum FocusControlMode: String, CaseIterable, Sendable {
    case continuousAuto
    case locked
    case manual
}

public enum ExposureControlMode: String, CaseIterable, Sendable {
    case continuousAuto
    case locked
    case customManual
}

public enum WhiteBalanceControlMode: String, CaseIterable, Sendable {
    case continuousAuto
    case locked
    case customKelvin
}

@MainActor
public final class CameraService: NSObject, ObservableObject {
    public static let shared = CameraService()
    
    // MARK: - Published Reactive State
    @Published public var isSessionRunning: Bool = false
    @Published public var currentPosition: AVCaptureDevice.Position = .back
    @Published public var currentLens: CameraLensType = .wide
    @Published public var availableLenses: [CameraLensType] = [.wide]
    
    // Hardware Controls State
    @Published public var focusMode: FocusControlMode = .continuousAuto
    @Published public var lensPosition: Float = 0.5 // 0.0 (near) to 1.0 (infinity)
    
    @Published public var exposureMode: ExposureControlMode = .continuousAuto
    @Published public var currentISO: Float = 100
    @Published public var minISO: Float = 50
    @Published public var maxISO: Float = 1600
    @Published public var exposureBias: Float = 0.0
    @Published public var minExposureBias: Float = -2.0
    @Published public var maxExposureBias: Float = 2.0
    
    @Published public var whiteBalanceMode: WhiteBalanceControlMode = .continuousAuto
    @Published public var currentKelvin: Float = 5500
    
    @Published public var zoomFactor: CGFloat = 1.0
    @Published public var minZoomFactor: CGFloat = 1.0
    @Published public var maxZoomFactor: CGFloat = 10.0
    
    @Published public var isTorchOn: Bool = false
    @Published public var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published public var isMultiCamSupported: Bool = AVCaptureMultiCamSession.isMultiCamSupported
    
    // MARK: - Internal Subsystem Objects
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.rewind52.camera.sessionQueue", qos: .userInitiated)
    private let videoDataOutputQueue = DispatchQueue(label: "com.rewind52.camera.videoQueue", qos: .userInteractive)
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    nonisolated(unsafe) public weak var delegate: CameraServiceDelegate?
    
    // Target frame rate throttling (e.g. 15fps, 30fps)
    nonisolated(unsafe) private var targetFrameRate: Int = 30
    nonisolated(unsafe) private var lastEmittedFrameTime: TimeInterval = 0
    
    public override init() {
        super.init()
    }
    
    // MARK: - Session Configuration & Lifecycle
    
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
        
        guard let device = selectCaptureDevice(for: .back, lens: .wide) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                self.videoDeviceInput = input
            }
            
            // Configure zero-copy 32BGRA uncompressed frame output
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            // Set default orientation
            if let connection = videoDataOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
            Task { @MainActor in
                self.isSessionRunning = self.captureSession.isRunning
                self.updateHardwareBoundaries(for: device)
            }
        } catch {
            captureSession.commitConfiguration()
            print("Failed to initialize capture session: \(error)")
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
    
    // MARK: - Camera Switching & Lens Selection
    
    public func switchCamera() {
        let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
        setCameraPosition(newPosition)
    }
    
    public func setCameraPosition(_ position: AVCaptureDevice.Position) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let newDevice = self.selectCaptureDevice(for: position, lens: .wide) else { return }
            
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
                
                if let connection = self.videoDataOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                    if position == .front && connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
                
                self.captureSession.commitConfiguration()
                
                Task { @MainActor in
                    self.currentPosition = position
                    self.currentLens = .wide
                    self.zoomFactor = 1.0
                    self.updateHardwareBoundaries(for: newDevice)
                }
            } catch {
                self.captureSession.commitConfiguration()
                print("Failed to switch camera position: \(error)")
            }
        }
    }
    
    public func selectLens(_ lens: CameraLensType) {
        guard currentPosition == .back else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let device = self.selectCaptureDevice(for: .back, lens: lens) else { return }
            
            self.captureSession.beginConfiguration()
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDeviceInput = newInput
                }
                
                if let connection = self.videoDataOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                }
                
                self.captureSession.commitConfiguration()
                
                Task { @MainActor in
                    self.currentLens = lens
                    self.zoomFactor = 1.0
                    self.updateHardwareBoundaries(for: device)
                }
            } catch {
                self.captureSession.commitConfiguration()
                print("Failed to select lens: \(error)")
            }
        }
    }
    
    // MARK: - Hardware Control 1: Focus (Manual, Locked, Continuous Auto)
    
    public func setManualFocus(lensPosition: Float) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            let clamped = max(0.0, min(1.0, lensPosition))
            
            do {
                try device.lockForConfiguration()
                if device.isLockingFocusWithCustomLensPositionSupported {
                    device.setFocusModeLocked(lensPosition: clamped) { _ in }
                } else if device.isFocusModeSupported(.locked) {
                    device.focusMode = .locked
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.focusMode = .manual
                    self?.lensPosition = clamped
                }
            } catch {
                print("Error setting manual focus: \(error)")
            }
        }
    }
    
    public func setFocusModeLocked() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.locked) {
                    device.focusMode = .locked
                }
                let currentPos = device.lensPosition
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.focusMode = .locked
                    self?.lensPosition = currentPos
                }
            } catch {
                print("Error locking focus: \(error)")
            }
        }
    }
    
    public func setContinuousAutoFocus() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.focusMode = .continuousAuto
                }
            } catch {
                print("Error setting auto focus: \(error)")
            }
        }
    }
    
    public func setFocusPointOfInterest(_ point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting focus point: \(error)")
            }
        }
    }
    
    // MARK: - Hardware Control 2: Exposure (Locked, Custom Manual ISO/Duration, Continuous Auto)
    
    public func setManualExposure(iso: Float, durationSeconds: Double? = nil) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            let clampedISO = max(device.activeFormat.minISO, min(iso, device.activeFormat.maxISO))
            
            let duration: CMTime
            if let durationSeconds = durationSeconds {
                let requested = CMTime(seconds: durationSeconds, preferredTimescale: 1000000)
                let minDur = device.activeFormat.minExposureDuration
                let maxDur = device.activeFormat.maxExposureDuration
                duration = max(minDur, min(requested, maxDur))
            } else {
                duration = device.exposureDuration
            }
            
            do {
                try device.lockForConfiguration()
                if device.isExposureModeSupported(.custom) {
                    device.setExposureModeCustom(duration: duration, iso: clampedISO) { _ in }
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.exposureMode = .customManual
                    self?.currentISO = clampedISO
                }
            } catch {
                print("Error setting manual exposure: \(error)")
            }
        }
    }
    
    public func setExposureModeLocked() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isExposureModeSupported(.locked) {
                    device.exposureMode = .locked
                }
                let iso = device.iso
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.exposureMode = .locked
                    self?.currentISO = iso
                }
            } catch {
                print("Error locking exposure: \(error)")
            }
        }
    }
    
    public func setContinuousAutoExposure() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.exposureMode = .continuousAuto
                }
            } catch {
                print("Error setting continuous auto exposure: \(error)")
            }
        }
    }
    
    public func setExposureTargetBias(_ bias: Float) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            let clamped = max(device.minExposureTargetBias, min(bias, device.maxExposureTargetBias))
            
            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(clamped) { _ in }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.exposureBias = clamped
                }
            } catch {
                print("Error setting exposure bias: \(error)")
            }
        }
    }
    
    public func setExposurePointOfInterest(_ point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting exposure point: \(error)")
            }
        }
    }
    
    // MARK: - Hardware Control 3: White Balance (Fixed Kelvin/Tint, Locked, Continuous Auto)
    
    public func setManualWhiteBalance(kelvin: Float, tint: Float = 0.0) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            
            let tempAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                temperature: max(2000.0, min(kelvin, 10000.0)),
                tint: max(-150.0, min(tint, 150.0))
            )
            
            var gains = device.deviceWhiteBalanceGains(for: tempAndTint)
            let maxGain = device.maxWhiteBalanceGain
            
            // Normalize & clamp gains within hardware envelope
            gains.redGain = max(1.0, min(gains.redGain, maxGain))
            gains.greenGain = max(1.0, min(gains.greenGain, maxGain))
            gains.blueGain = max(1.0, min(gains.blueGain, maxGain))
            
            do {
                try device.lockForConfiguration()
                if device.isLockingWhiteBalanceWithCustomDeviceGainsSupported {
                    device.setWhiteBalanceModeLocked(with: gains) { _ in }
                } else if device.isWhiteBalanceModeSupported(.locked) {
                    device.whiteBalanceMode = .locked
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.whiteBalanceMode = .customKelvin
                    self?.currentKelvin = kelvin
                }
            } catch {
                print("Error setting manual white balance: \(error)")
            }
        }
    }
    
    public func setWhiteBalanceModeLocked() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isWhiteBalanceModeSupported(.locked) {
                    device.whiteBalanceMode = .locked
                }
                let tempAndTint = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.whiteBalanceMode = .locked
                    self?.currentKelvin = tempAndTint.temperature
                }
            } catch {
                print("Error locking white balance: \(error)")
            }
        }
    }
    
    public func setContinuousAutoWhiteBalance() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.whiteBalanceMode = .continuousAuto
                }
            } catch {
                print("Error setting auto white balance: \(error)")
            }
        }
    }
    
    // MARK: - Hardware Control 4: Zoom & Torch
    
    public func setZoom(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            let clamped = max(device.minAvailableVideoZoomFactor, min(factor, min(device.maxAvailableVideoZoomFactor, 10.0)))
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.zoomFactor = clamped
                }
            } catch {
                print("Failed to set video zoom: \(error)")
            }
        }
    }
    
    public func toggleTorch() {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                let nextTorchState = (device.torchMode != .on)
                if nextTorchState {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
                
                Task { @MainActor in
                    self?.isTorchOn = nextTorchState
                }
            } catch {
                print("Failed to toggle torch: \(error)")
            }
        }
    }
    
    public func setEraConfiguration(_ era: EraModel) {
        self.targetFrameRate = era.video.frameRate
        
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                
                // Hardware exposure lock replication
                if era.video.autoExposureLock && device.isExposureModeSupported(.locked) {
                    device.exposureMode = .locked
                } else if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                // Fixed white balance cast replication
                if era.video.whiteBalanceKelvin > 0 {
                    if device.isLockingWhiteBalanceWithCustomDeviceGainsSupported {
                        let tempAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                            temperature: era.video.whiteBalanceKelvin,
                            tint: 0.0
                        )
                        var gains = device.deviceWhiteBalanceGains(for: tempAndTint)
                        let maxGain = device.maxWhiteBalanceGain
                        gains.redGain = max(1.0, min(gains.redGain, maxGain))
                        gains.greenGain = max(1.0, min(gains.greenGain, maxGain))
                        gains.blueGain = max(1.0, min(gains.blueGain, maxGain))
                        device.setWhiteBalanceModeLocked(with: gains) { _ in }
                    } else if device.isWhiteBalanceModeSupported(.locked) {
                        device.whiteBalanceMode = .locked
                    }
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Failed to apply era hardware config: \(error)")
            }
        }
    }
    
    // MARK: - Device Discovery & Bounds Helpers
    
    private func updateHardwareBoundaries(for device: AVCaptureDevice) {
        self.minZoomFactor = device.minAvailableVideoZoomFactor
        self.maxZoomFactor = min(device.maxAvailableVideoZoomFactor, 10.0)
        self.minISO = device.activeFormat.minISO
        self.maxISO = device.activeFormat.maxISO
        self.minExposureBias = device.minExposureTargetBias
        self.maxExposureBias = device.maxExposureTargetBias
        self.currentISO = device.iso
        self.lensPosition = device.lensPosition
        
        // Discover available physical lenses on back camera
        if device.position == .back {
            var lenses: [CameraLensType] = [.wide]
            if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil {
                lenses.append(.ultraWide)
            }
            if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil {
                lenses.append(.telephoto)
            }
            self.availableLenses = lenses.sorted { $0.rawValue < $1.rawValue }
        } else {
            self.availableLenses = [.wide]
        }
    }
    
    private func selectCaptureDevice(for position: AVCaptureDevice.Position, lens: CameraLensType) -> AVCaptureDevice? {
        if position == .front {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
        
        switch lens {
        case .ultraWide:
            return AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .telephoto:
            return AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        case .wide:
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            )
            return discovery.devices.first ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Target frame rate throttling (e.g. 10fps, 15fps, 30fps)
        let now = CACurrentMediaTime()
        let minFrameInterval = 1.0 / Double(max(1, targetFrameRate))
        
        if now - lastEmittedFrameTime >= minFrameInterval * 0.92 {
            self.lastEmittedFrameTime = now
            self.delegate?.cameraService(self, didOutput: pixelBuffer, presentationTime: presentationTime)
        }
    }
}
