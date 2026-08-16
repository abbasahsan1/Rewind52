//
//  PhotoLibraryExporter.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import Photos
import UIKit
import AVFoundation

public enum ExportAspectRatio: String, CaseIterable, Identifiable, Sendable {
    case original = "Original"
    case social9_16 = "9:16 (TikTok/Reels)"
    case classic4_3 = "4:3 (Pillarbox)"
    
    public var id: String { rawValue }
}

public final class PhotoLibraryExporter: Sendable {
    public static let shared = PhotoLibraryExporter()
    
    private init() {}
    
    /// Exports video to Photos library with optional aspect ratio formatting.
    public func exportToPhotoLibrary(
        videoURL: URL,
        aspectRatio: ExportAspectRatio,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(.failure(NSError(domain: "PhotoLibraryExporter", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])))
                return
            }
            
            Task {
                do {
                    let exportURL: URL
                    if aspectRatio == .original {
                        exportURL = videoURL
                    } else {
                        exportURL = try await Self.convertAspectRatio(sourceURL: videoURL, targetRatio: aspectRatio)
                    }
                    
                    try await PHPhotoLibrary.shared().performChanges {
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .video, fileURL: exportURL, options: nil)
                    }
                    
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func convertAspectRatio(sourceURL: URL, targetRatio: ExportAspectRatio) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return sourceURL
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(transform)
        let srcWidth = abs(transformedSize.width)
        let srcHeight = abs(transformedSize.height)
        
        var renderWidth: CGFloat = srcWidth
        var renderHeight: CGFloat = srcHeight
        
        if targetRatio == .social9_16 {
            // 9:16 target (e.g. 1080x1920)
            renderHeight = srcHeight
            renderWidth = renderHeight * (9.0 / 16.0)
        } else if targetRatio == .classic4_3 {
            // 4:3 target
            renderWidth = srcWidth
            renderHeight = renderWidth * (3.0 / 4.0)
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("Rewind52_Export_\(UUID().uuidString.prefix(6)).mp4")
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return sourceURL
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        let duration = try await asset.load(.duration)
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // Center crop/scale
        let scaleX = renderWidth / srcWidth
        let scaleY = renderHeight / srcHeight
        let scale = max(scaleX, scaleY)
        
        var finalTransform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        let dx = (renderWidth - srcWidth * scale) / 2.0
        let dy = (renderHeight - srcHeight * scale) / 2.0
        finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: dx, y: dy))
        
        layerInstruction.setTransform(finalTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            return outputURL
        } else if let error = exportSession.error {
            throw error
        }
        
        return sourceURL
    }
}
