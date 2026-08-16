//
//  GalleryManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import Combine

public struct RecordedVideoItem: Identifiable, Sendable {
    public let id: UUID
    public let fileURL: URL
    public let eraId: String
    public let eraName: String
    public let year: Int
    public let createdAt: Date
    public let duration: TimeInterval
    public let thumbnail: UIImage?
    
    public init(
        id: UUID = UUID(),
        fileURL: URL,
        eraId: String,
        eraName: String,
        year: Int,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        thumbnail: UIImage? = nil
    ) {
        self.id = id
        self.fileURL = fileURL
        self.eraId = eraId
        self.eraName = eraName
        self.year = year
        self.createdAt = createdAt
        self.duration = duration
        self.thumbnail = thumbnail
    }
}

@MainActor
public final class GalleryManager: ObservableObject {
    public static let shared = GalleryManager()
    
    @Published public var items: [RecordedVideoItem] = []
    
    private let storageDir: URL
    
    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.storageDir = docs.appendingPathComponent("Recordings", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
        loadItems()
    }
    
    public func loadItems() {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: storageDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        let videoURLs = fileURLs.filter { $0.pathExtension.lowercased() == "mp4" || $0.pathExtension.lowercased() == "mov" }
        
        var loaded: [RecordedVideoItem] = []
        for url in videoURLs {
            let asset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(asset.duration)
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let creationDate = attrs?[.creationDate] as? Date ?? Date()
            
            // Extract era year from filename if possible
            var year = 1988
            let name = url.lastPathComponent
            if let regex = try? NSRegularExpression(pattern: #"(\d{4})"#),
               let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) {
                if let range = Range(match.range(at: 1), in: name) {
                    year = Int(name[range]) ?? 1988
                }
            }
            
            let era = EraRegistry.shared.era(forYear: year)
            let thumb = generateThumbnail(for: url)
            
            loaded.append(RecordedVideoItem(
                fileURL: url,
                eraId: era?.id ?? "era_1988_vhs",
                eraName: era?.name ?? "1988 VHS",
                year: year,
                createdAt: creationDate,
                duration: duration.isNaN ? 0 : duration,
                thumbnail: thumb
            ))
        }
        
        self.items = loaded.sorted { $0.createdAt > $1.createdAt }
    }
    
    public func addVideo(url: URL, era: EraModel) {
        let destURL = storageDir.appendingPathComponent("Rewind52_\(era.year)_\(UUID().uuidString.prefix(6)).mp4")
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: url, to: destURL)
            
            let asset = AVURLAsset(url: destURL)
            let duration = CMTimeGetSeconds(asset.duration)
            let thumb = generateThumbnail(for: destURL)
            
            let newItem = RecordedVideoItem(
                fileURL: destURL,
                eraId: era.id,
                eraName: era.name,
                year: era.year,
                createdAt: Date(),
                duration: duration.isNaN ? 0 : duration,
                thumbnail: thumb
            )
            
            self.items.insert(newItem, at: 0)
        } catch {
            print("Failed to save recorded video: \(error)")
        }
    }
    
    public func deleteItem(_ item: RecordedVideoItem) {
        try? FileManager.default.removeItem(at: item.fileURL)
        items.removeAll { $0.id == item.id }
    }
    
    private func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        if let imageRef = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: imageRef)
        }
        return nil
    }
}
