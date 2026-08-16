//
//  AuthenticityPipeline.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreGraphics
import CoreMedia

public actor AuthenticityPipeline {
    public static let shared = AuthenticityPipeline()
    
    private init() {}
    
    /// Executes the multi-pass Authenticity Post-Processing Pipeline:
    /// - Pass 1: Raw Captured Video
    /// - Pass 2: Low-Bitrate 320x240 Codec Crunch + 8kHz Audio Downsampling
    /// - Pass 3: Decoding & Baking Artifacts into final modern H.264/AAC Master MP4
    public func processRecording(
        sourceURL: URL,
        era: EraModel,
        onProgress: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration)
        let totalSeconds = duration.seconds
        guard totalSeconds > 0.1 else { return sourceURL }
        
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let crunchedURL = tempDir.appendingPathComponent("crunched_\(UUID().uuidString.prefix(6)).mp4")
        let finalMasterURL = outputDir.appendingPathComponent("Rewind52_\(era.year)_\(UUID().uuidString.prefix(6)).mp4")
        
        try? FileManager.default.removeItem(at: crunchedURL)
        try? FileManager.default.removeItem(at: finalMasterURL)
        
        // -------------------------------------------------------------
        // PASS 2: LOW-BITRATE CODEC CRUNCH (320x240 @ 128kbps + 8kHz PCM)
        // -------------------------------------------------------------
        onProgress?(0.05, "Pass 1/2: Crunching to 320x240 low-bitrate H.264 & 8kHz audio...")
        try await executePass2Crunch(
            sourceAsset: asset,
            outputURL: crunchedURL,
            totalSeconds: totalSeconds,
            onProgress: { p in
                onProgress?(p * 0.45, "Pass 1/2: Crunching codec artifacts...")
            }
        )
        
        // -------------------------------------------------------------
        // PASS 3: ARTIFACT BAKING & FINAL MASTER MUX (H.264 / AAC MP4)
        // -------------------------------------------------------------
        onProgress?(0.50, "Pass 2/2: Baking macroblocks permanently into final master...")
        let crunchedAsset = AVURLAsset(url: crunchedURL)
        try await executePass3Bake(
            crunchedAsset: crunchedAsset,
            outputURL: finalMasterURL,
            era: era,
            totalSeconds: totalSeconds,
            onProgress: { p in
                onProgress?(0.50 + p * 0.50, "Pass 2/2: Finalizing MP4 container...")
            }
        )
        
        // Cleanup intermediate temp files
        try? FileManager.default.removeItem(at: crunchedURL)
        if sourceURL != finalMasterURL {
            try? FileManager.default.removeItem(at: sourceURL)
        }
        
        onProgress?(1.0, "Authenticity processing complete!")
        return finalMasterURL
    }
    
    // MARK: - Pass 2: Low-Bitrate 320x240 & 8kHz Downsampler
    
    private func executePass2Crunch(
        sourceAsset: AVAsset,
        outputURL: URL,
        totalSeconds: Double,
        onProgress: (@Sendable (Double) -> Void)?
    ) async throws {
        guard let videoTrack = try await sourceAsset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "AuthenticityPipeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }
        let audioTrack = try await sourceAsset.loadTracks(withMediaType: .audio).first
        
        let reader = try AVAssetReader(asset: sourceAsset)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // Reader Video Settings
        let readerVideoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let readerVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerVideoSettings)
        if reader.canAdd(readerVideoOutput) { reader.add(readerVideoOutput) }
        
        // Low-Bitrate 320x240 Video Writer Settings
        let crunchVideoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 320,
            AVVideoHeightKey: 240,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 128_000, // Ultra-low 128kbps bitrate to force macroblocking
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoExpectedSourceFrameRateKey: 15,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]
        let writerVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: crunchVideoSettings)
        writerVideoInput.expectsMediaDataInRealTime = false
        if writer.canAdd(writerVideoInput) { writer.add(writerVideoInput) }
        
        // 8kHz Downsampled Audio Settings
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
            
            // 8kHz Mono AAC downsampling
            let crunchAudioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 8000.0, // 8kHz telephone bandwidth
                AVEncoderBitRateKey: 32_000
            ]
            let wAudioIn = AVAssetWriterInput(mediaType: .audio, outputSettings: crunchAudioSettings)
            wAudioIn.expectsMediaDataInRealTime = false
            if writer.canAdd(wAudioIn) {
                writer.add(wAudioIn)
                writerAudioInput = wAudioIn
            }
        }
        
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Pump Video Frames
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "com.rewind52.crunch.videoQueue")
            writerVideoInput.requestMediaDataWhenReady(on: queue) {
                while writerVideoInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerVideoOutput.copyNextSampleBuffer() {
                        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        let progress = min(1.0, max(0.0, time.seconds / max(0.1, totalSeconds)))
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
        
        // Pump Audio Samples
        if let readerAudioOutput = readerAudioOutput, let writerAudioInput = writerAudioInput {
            await withCheckedContinuation { continuation in
                let queue = DispatchQueue(label: "com.rewind52.crunch.audioQueue")
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
    }
    
    // MARK: - Pass 3: Artifact Baking & High-Bitrate Final MP4 Mux
    
    private func executePass3Bake(
        crunchedAsset: AVAsset,
        outputURL: URL,
        era: EraModel,
        totalSeconds: Double,
        onProgress: (@Sendable (Double) -> Void)?
    ) async throws {
        guard let videoTrack = try await crunchedAsset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "AuthenticityPipeline", code: -1, userInfo: [NSLocalizedDescriptionKey: "No crunched video track found"])
        }
        let audioTrack = try await crunchedAsset.loadTracks(withMediaType: .audio).first
        
        let reader = try AVAssetReader(asset: crunchedAsset)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // Decode low-res crunched video
        let readerVideoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let readerVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerVideoSettings)
        if reader.canAdd(readerVideoOutput) { reader.add(readerVideoOutput) }
        
        // Encode at target era master resolution (e.g. 1080x1920 or 720x480) with high bitrate to bake in artifacts
        let masterWidth = (era.video.resolutionWidth > 320) ? era.video.resolutionWidth : 1080
        let masterHeight = (era.video.resolutionHeight > 240) ? era.video.resolutionHeight : 1920
        
        let bakeVideoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: masterWidth,
            AVVideoHeightKey: masterHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000, // 10Mbps clean master stream
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        let writerVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: bakeVideoSettings)
        writerVideoInput.expectsMediaDataInRealTime = false
        if writer.canAdd(writerVideoInput) { writer.add(writerVideoInput) }
        
        // Audio pass-through / high-quality AAC mux
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
            
            let bakeAudioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 192_000
            ]
            let wAudioIn = AVAssetWriterInput(mediaType: .audio, outputSettings: bakeAudioSettings)
            wAudioIn.expectsMediaDataInRealTime = false
            if writer.canAdd(wAudioIn) {
                writer.add(wAudioIn)
                writerAudioInput = wAudioIn
            }
        }
        
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Pump Video Frames
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "com.rewind52.bake.videoQueue")
            writerVideoInput.requestMediaDataWhenReady(on: queue) {
                while writerVideoInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerVideoOutput.copyNextSampleBuffer() {
                        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        let progress = min(1.0, max(0.0, time.seconds / max(0.1, totalSeconds)))
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
        
        // Pump Audio Samples
        if let readerAudioOutput = readerAudioOutput, let writerAudioInput = writerAudioInput {
            await withCheckedContinuation { continuation in
                let queue = DispatchQueue(label: "com.rewind52.bake.audioQueue")
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
    }
}
