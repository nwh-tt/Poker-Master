import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    // Add all your subscription product IDs
    private let productIDs = [
        "com.pokermaster.pro.weekly",
        "com.pokermaster.pro.monthly",
        "com.pokermaster.pro.yearly"
    ]
    
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
            print(products)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    
    
    // Purchase a product
    func purchase(timeFrame: String) async {
        guard let productID = productID(for: timeFrame),
        let product = products.first(where: { $0.id == productID }) else {
            print("No product found for \(timeFrame)")
            return
        }
            
        await purchaseProduct(product)
        // once complete update purchased products
        await requestProducts()
    }
    
    func purchaseProduct(_ product: Product) async {
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
        
    private func productID(for timeFrame: String) -> String? {
        switch timeFrame.lowercased() {
        case "weekly": return "com.pokermaster.pro.weekly"
        case "monthly": return "com.pokermaster.pro.monthly"
        case "yearly": return "com.pokermaster.pro.yearly"
        default: return nil
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
    
    // Check if any subscription is active
    func isSubscribed() -> Bool {
        !purchasedProductIDs.isEmpty
    }
    
    // Optional convenience function: check which tier is active
    func activeSubscriptionTier() -> String? {
        if purchasedProductIDs.contains("com.pokermaster.pro.yearly") {
            return "Yearly"
        } else if purchasedProductIDs.contains("com.pokermaster.pro.monthly") {
            return "Monthly"
        } else if purchasedProductIDs.contains("com.pokermaster.pro.weekly") {
            return "Weekly"
        }
        return nil
    }
    
    func isEligibleForTrial() async -> Bool {
        guard let product = products.first(where: { $0.id == "com.pokermaster.pro.monthly" }),
        let subscription = product.subscription else {
            print("No monthly subscription available")
            return false
        }
        return await subscription.isEligibleForIntroOffer
    }
    
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

}
