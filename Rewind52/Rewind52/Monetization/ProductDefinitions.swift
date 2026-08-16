//
//  ProductDefinitions.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation

public struct ProductDefinitions {
    public static let proMonthlySubscriptionID = "cognetex.Rewind52.pro.monthly" // $4.99/mo
    public static let proLifetimeID = "cognetex.Rewind52.pro.lifetime"           // $29.99
    
    public static func eraPackID(for eraId: String) -> String {
        "cognetex.Rewind52.era.\(eraId)"                                        // $0.99
    }
    
    public static var allProductIDs: Set<String> {
        var ids: Set<String> = [proMonthlySubscriptionID, proLifetimeID]
        for era in EraRegistry.shared.eras where !era.isFree {
            ids.insert(eraPackID(for: era.id))
        }
        return ids
    }
}
