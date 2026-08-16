//
//  VideoWriter.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import AVFoundation
import CoreVideo
import CoreMedia

public protocol VideoWriterDelegate: AnyObject, Sendable {
    func videoWriterDidFinishRecording(outputURL: URL, era: EraModel)
    func videoWriterDidEncounterError(_ error: Error)
}

public final class VideoWriter: @unchecked Sendable {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private let writerQueue = DispatchQueue(label: "com.rewind52.videowriter.queue", qos: .userInitiated)
    private var isRecording: Bool = false
    private var startTime: CMTime = .invalid
    private var outputURL: URL?
    private var currentEra: EraModel?
    
    // Native Target Framerate Locking state (e.g. exactly 15 fps)
    private var targetFPS: Int32 = 30
    private var recordedFrameIndex: Int64 = 0
    
    public weak var delegate: VideoWriterDelegate?
    
    public init() {}
    
    public func startRecording(
        era: EraModel,
        outputSize: CGSize,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        writerQueue.async { [weak self] in
            guard let self = self else { return }
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "Rewind52_\(era.year)_\(UUID().uuidString.prefix(8)).mp4"
            let url = tempDir.appendingPathComponent(fileName)
            
            // Remove existing file if any
            try? FileManager.default.removeItem(at: url)
            
            do {
                let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
                
                let fps = Int32(max(1, era.video.frameRate))
                self.targetFPS = fps
                self.recordedFrameIndex = 0
                
                // Video compression settings with native locked target framerate
                let videoCompressionProperties: [String: Any] = [
                    AVVideoAverageBitRateKey: max(500_000, era.audio.bitrate * 8),
                    AVVideoMaxKeyFrameIntervalKey: Int(fps * 2),
                    AVVideoExpectedSourceFrameRateKey: Int(fps)
                ]
                
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: Int(outputSize.width),
                    AVVideoHeightKey: Int(outputSize.height),
                    AVVideoCompressionPropertiesKey: videoCompressionProperties
                ]
                
                let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                vInput.expectsMediaDataInRealTime = true
                vInput.mediaTimeScale = fps
                
                let pixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: Int(outputSize.width),
                    kCVPixelBufferHeightKey as String: Int(outputSize.height)
                ]
                
                let adp = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: vInput,
                    sourcePixelBufferAttributes: pixelBufferAttributes
                )
                
                // Audio settings
                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVNumberOfChannelsKey: era.audio.channels,
                    AVSampleRateKey: era.audio.sampleRate,
                    AVEncoderBitRateKey: era.audio.bitrate
                ]
                
                let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                aInput.expectsMediaDataInRealTime = true
                
                if writer.canAdd(vInput) { writer.add(vInput) }
                if writer.canAdd(aInput) { writer.add(aInput) }
                
                writer.startWriting()
                
                self.assetWriter = writer
                self.videoInput = vInput
                self.audioInput = aInput
                self.adaptor = adp
                self.outputURL = url
                self.currentEra = era
                self.isRecording = true
                self.startTime = .invalid
                
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func appendVideoFrame(_ pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        writerQueue.async { [weak self] in
            guard let self = self,
                  self.isRecording,
                  let writer = self.assetWriter,
                  writer.status == .writing,
                  let vInput = self.videoInput,
                  vInput.isReadyForMoreMediaData,
                  let adaptor = self.adaptor else {
                return
            }
            
            // Native locked timestamp progression (e.g. exact 1/15s steps)
            let frameTime = CMTime(value: self.recordedFrameIndex, timescale: self.targetFPS)
            
            if self.startTime == .invalid {
                self.startTime = frameTime
                writer.startSession(atSourceTime: frameTime)
            }
            
            adaptor.append(pixelBuffer, withPresentationTime: frameTime)
            self.recordedFrameIndex += 1
        }
    }
    
    public func appendAudioBuffer(_ pcmBuffer: AVAudioPCMBuffer, presentationTime: CMTime) {
        writerQueue.async { [weak self] in
            guard let self = self,
                  self.isRecording,
                  let writer = self.assetWriter,
                  writer.status == .writing,
                  let aInput = self.audioInput,
                  aInput.isReadyForMoreMediaData else {
                return
            }
            
            if self.startTime == .invalid {
                return // Wait for first video frame to establish startSession
            }
            
            guard let sampleBuffer = self.createSampleBuffer(from: pcmBuffer, presentationTime: presentationTime) else {
                return
            }
            
            aInput.append(sampleBuffer)
        }
    }
    
    public func finishRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        writerQueue.async { [weak self] in
            guard let self = self,
                  let writer = self.assetWriter,
                  let outputURL = self.outputURL,
                  let era = self.currentEra else {
                completion(.failure(NSError(domain: "VideoWriter", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active recording session"])))
                return
            }
            
            self.isRecording = false
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()
            
            writer.finishWriting {
                if writer.status == .completed {
                    self.delegate?.videoWriterDidFinishRecording(outputURL: outputURL, era: era)
                    completion(.success(outputURL))
                } else if let error = writer.error {
                    self.delegate?.videoWriterDidEncounterError(error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createSampleBuffer(from pcmBuffer: AVAudioPCMBuffer, presentationTime: CMTime) -> CMSampleBuffer? {
        var formatDesc: CMAudioFormatDescription?
        let asbd = pcmBuffer.format.streamDescription
        let status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDesc
        )
        guard status == noErr, let formatDesc = formatDesc else { return nil }
        
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: CMTimeScale(pcmBuffer.format.sampleRate)),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleCount: CMItemCount(pcmBuffer.frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr, let sampleBuffer = sampleBuffer else { return nil }
        
        let audioBufferList = pcmBuffer.mutableAudioBufferList
        let blockBufferStatus = CMSampleBufferSetDataBufferFromAudioBufferList(
            sampleBuffer,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: 0,
            bufferList: audioBufferList
        )
        
        guard blockBufferStatus == noErr else { return nil }
        return sampleBuffer
    }
}
