//
//  AuthenticityPipeline.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreGraphics

public actor AuthenticityPipeline {
    public static let shared = AuthenticityPipeline()
    
    private init() {}
    
    /// Executes multi-pass hardware/codec degradation and authenticity re-encoding.
    public func processRecording(
        sourceURL: URL,
        era: EraModel,
        onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        // If era has no extra post-processing steps (e.g. Modern reference), return source directly
        if era.export.pipelineSteps.isEmpty {
            onProgress?(1.0)
            return sourceURL
        }
        
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration)
        let totalSeconds = duration.seconds
        guard totalSeconds > 0.1 else { return sourceURL }
        
        let outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let finalURL = outputDir.appendingPathComponent("Rewind52_Master_\(era.year)_\(UUID().uuidString.prefix(6)).mp4")
        
        try? FileManager.default.removeItem(at: finalURL)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return sourceURL
        }
        let audioTrack = try await asset.loadTracks(withMediaType: .audio).first
        
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: finalURL, fileType: .mp4)
        
        // 1. Configure Video Reader Output
        let readerVideoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let readerVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerVideoSettings)
        if reader.canAdd(readerVideoOutput) { reader.add(readerVideoOutput) }
        
        // 2. Configure Video Writer Input with authentic era bitrates & resolution
        let targetWidth = era.video.resolutionWidth
        let targetHeight = era.video.resolutionHeight
        let targetBitrate = (era.category == .mobileEarlySmartphone) ? 128_000 : (era.category == .analogBroadcast ? 800_000 : 2_500_000)
        
        let writerVideoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: targetWidth,
            AVVideoHeightKey: targetHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: targetBitrate,
                AVVideoMaxKeyFrameIntervalKey: era.video.frameRate * 2,
                AVVideoExpectedSourceFrameRateKey: era.video.frameRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]
        
        let writerVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: writerVideoSettings)
        writerVideoInput.expectsMediaDataInRealTime = false
        if writer.canAdd(writerVideoInput) { writer.add(writerVideoInput) }
        
        // 3. Configure Audio Reader & Writer
        var readerAudioOutput: AVAssetReaderTrackOutput?
        var writerAudioInput: AVAssetWriterInput?
        
        if let audioTrack = audioTrack {
            let readerAudioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM
            ]
            let rAudioOut = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: readerAudioSettings)
            if reader.canAdd(rAudioOut) {
                reader.add(rAudioOut)
                readerAudioOutput = rAudioOut
            }
            
            let writerAudioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: era.audio.channels,
                AVSampleRateKey: era.audio.sampleRate,
                AVEncoderBitRateKey: era.audio.bitrate
            ]
            let wAudioIn = AVAssetWriterInput(mediaType: .audio, outputSettings: writerAudioSettings)
            wAudioIn.expectsMediaDataInRealTime = false
            if writer.canAdd(wAudioIn) {
                writer.add(wAudioIn)
                writerAudioInput = wAudioIn
            }
        }
        
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Process Video Frames
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "com.rewind52.authenticity.passQueue")
            
            writerVideoInput.requestMediaDataWhenReady(on: queue) {
                while writerVideoInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerVideoOutput.copyNextSampleBuffer() {
                        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        let progress = min(0.95, time.seconds / totalSeconds)
                        onProgress?(progress)
                        
                        writerVideoInput.append(sampleBuffer)
                    } else {
                        writerVideoInput.markAsFinished()
                        continuation.resume()
                        break
                    }
                }
            }
        }
        
        // Process Audio Samples
        if let readerAudioOutput = readerAudioOutput, let writerAudioInput = writerAudioInput {
            await withCheckedContinuation { continuation in
                let queue = DispatchQueue(label: "com.rewind52.authenticity.audioPassQueue")
                writerAudioInput.requestMediaDataWhenReady(on: queue) {
                    while writerAudioInput.isReadyForMoreMediaData {
                        if let sampleBuffer = readerAudioOutput.copyNextSampleBuffer() {
                            writerAudioInput.append(sampleBuffer)
                        } else {
                            writerAudioInput.markAsFinished()
                            continuation.resume()
                            break
                        }
                    }
                }
            }
        }
        
        await writer.finishWriting()
        onProgress?(1.0)
        
        // Clean up temp source if different
        if sourceURL != finalURL {
            try? FileManager.default.removeItem(at: sourceURL)
        }
        
        return finalURL
    }
}
