//
//  EraJSONLoader.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation

public final class EraJSONLoader: Sendable {
    public static let shared = EraJSONLoader()
    
    public init() {}
    
    /// Loads and deserializes EraModel definitions from JSON data.
    public func loadEras(from jsonData: Data) throws -> [EraModel] {
        let decoder = JSONDecoder()
        return try decoder.decode([EraModel].self, from: jsonData)
    }
    
    /// Loads EraModel definitions from a bundled or local JSON file.
    public func loadEras(from fileURL: URL) throws -> [EraModel] {
        let data = try Data(contentsOf: fileURL)
        return try loadEras(from: data)
    }
    
    /// Encodes an array of EraModel objects to a pretty-printed JSON string.
    public func encodeErasToJSON(_ eras: [EraModel]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(eras)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "EraJSONLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert encoded JSON data to String"])
        }
        return string
    }
}
