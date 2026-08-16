//
//  MultiCamService.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreVideo
import Combine

public protocol MultiCamServiceDelegate: AnyObject, Sendable {
    func multiCamService(_ service: MultiCamService, didOutputBackFrame pixelBuffer: CVPixelBuffer, time: CMTime)
    func multiCamService(_ service: MultiCamService, didOutputFrontFrame pixelBuffer: CVPixelBuffer, time: CMTime)
}

@MainActor
public final class MultiCamService: NSObject, ObservableObject {
    public static let shared = MultiCamService()
    
    @Published public var isRunning: Bool = false
    @Published public var isSupported: Bool = AVCaptureMultiCamSession.isMultiCamSupported
    
    nonisolated(unsafe) private var multiCamSession: AVCaptureMultiCamSession?
    private let multiCamQueue = DispatchQueue(label: "com.rewind52.multicam.queue", qos: .userInitiated)
    
    nonisolated(unsafe) private let backDataOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private let frontDataOutput = AVCaptureVideoDataOutput()
    
    nonisolated(unsafe) public weak var delegate: MultiCamServiceDelegate?
    
    public override init() {
        super.init()
    }
    
    public func startMultiCam() {
        guard isSupported else { return }
        
        multiCamQueue.async { [weak self] in
            self?.setupMultiCamSession()
        }
    }
    
    public func stopMultiCam() {
        multiCamQueue.async { [weak self] in
            guard let self = self, let session = self.multiCamSession else { return }
            session.stopRunning()
            self.multiCamSession = nil
            Task { @MainActor in
                self.isRunning = false
            }
        }
    }
    
    private func setupMultiCamSession() {
        let session = AVCaptureMultiCamSession()
        session.beginConfiguration()
        
        guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            session.commitConfiguration()
            return
        }
        
        do {
            let backInput = try AVCaptureDeviceInput(device: backDevice)
            let frontInput = try AVCaptureDeviceInput(device: frontDevice)
            
            if session.canAddInput(backInput) { session.addInputWithNoConnections(backInput) }
            if session.canAddInput(frontInput) { session.addInputWithNoConnections(frontInput) }
            
            // Connect Back Camera Output
            backDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            backDataOutput.setSampleBufferDelegate(self, queue: multiCamQueue)
            if session.canAddOutput(backDataOutput) { session.addOutputWithNoConnections(backDataOutput) }
            
            if let backPort = backInput.ports(for: .video, sourceDeviceType: backDevice.deviceType, sourceDevicePosition: .back).first {
                let backConnection = AVCaptureConnection(inputPorts: [backPort], output: backDataOutput)
                if session.canAddConnection(backConnection) {
                    session.addConnection(backConnection)
                    if backConnection.isVideoRotationAngleSupported(90) {
                        backConnection.videoRotationAngle = 90
                    }
                }
            }
            
            // Connect Front Camera Output
            frontDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            frontDataOutput.setSampleBufferDelegate(self, queue: multiCamQueue)
            if session.canAddOutput(frontDataOutput) { session.addOutputWithNoConnections(frontDataOutput) }
            
            if let frontPort = frontInput.ports(for: .video, sourceDeviceType: frontDevice.deviceType, sourceDevicePosition: .front).first {
                let frontConnection = AVCaptureConnection(inputPorts: [frontPort], output: frontDataOutput)
                if session.canAddConnection(frontConnection) {
                    session.addConnection(frontConnection)
                    if frontConnection.isVideoRotationAngleSupported(90) {
                        frontConnection.videoRotationAngle = 90
                    }
                    if frontConnection.isVideoMirroringSupported {
                        frontConnection.isVideoMirrored = true
                    }
                }
            }
            
            session.commitConfiguration()
            session.startRunning()
            
            self.multiCamSession = session
            Task { @MainActor in
                self.isRunning = session.isRunning
            }
        } catch {
            session.commitConfiguration()
            print("Failed to setup AVCaptureMultiCamSession: \(error)")
        }
    }
}

extension MultiCamService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if output === backDataOutput {
            self.delegate?.multiCamService(self, didOutputBackFrame: pixelBuffer, time: time)
        } else if output === frontDataOutput {
            self.delegate?.multiCamService(self, didOutputFrontFrame: pixelBuffer, time: time)
        }
    }
}
