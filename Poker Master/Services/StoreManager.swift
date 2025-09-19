//
//  StoreManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 9/17/25.
//

import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIDs = ["com.yourapp.pro.monthly"]
    
    init() {
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    // Load products from App Store
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    // Purchase a product
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIDs.insert(product.id)
                    await transaction.finish()
                }
            default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    // Restore purchases
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
    
    func isSubscribed() -> Bool {
        !purchasedProductIDs.isEmpty
    }
}

