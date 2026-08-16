//
//  StoreKitManager.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation
import StoreKit
import Combine

@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()
    
    @Published public var availableProducts: [Product] = []
    @Published public var isPurchasing: Bool = false
    @Published public var errorMessage: String?
    
    private var transactionListenerTask: Task<Void, Error>?
    
    public init() {
        self.transactionListenerTask = listenForTransactions()
        Task {
            await fetchProducts()
            await updateCurrentEntitlements()
        }
    }
    
    deinit {
        transactionListenerTask?.cancel()
    }
    
    public func fetchProducts() async {
        do {
            let products = try await Product.products(for: ProductDefinitions.allProductIDs)
            self.availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            print("StoreKit fetch error: \(error)")
        }
    }
    
    public func purchase(product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            isPurchasing = false
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleSuccessfulTransaction(transaction)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateCurrentEntitlements()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func updateCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                await handleSuccessfulTransaction(transaction)
            }
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.handleSuccessfulTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }
    
    private func handleSuccessfulTransaction(_ transaction: Transaction) async {
        let entitlementMgr = EntitlementManager.shared
        if transaction.productID == ProductDefinitions.proMonthlySubscriptionID ||
            transaction.productID == ProductDefinitions.proLifetimeID {
            entitlementMgr.unlockPro()
        } else if transaction.productID.contains("cognetex.Rewind52.era.") {
            let eraId = transaction.productID.replacingOccurrences(of: "cognetex.Rewind52.era.", with: "")
            entitlementMgr.unlockEra(id: eraId)
        }
    }
    
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
