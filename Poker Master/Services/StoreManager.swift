import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    // Task to hold the listener for transaction updates
    private var updates: Task<Void, Never>?
    
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
        
        // Listens for any transaction updates
        updates = listenForTransactions()
    }
    
    deinit {
        // ** 2. Cancel the listener when the object is deallocated **
        updates?.cancel()
    }
    
    // Load products from App Store
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            // Iterate over all transactions that the App Store sends to us.
            for await result in Transaction.updates {
                do {
                    // Check if the transaction is verified
                    let transaction = try self.checkVerified(result)
                    
                    // Process the verified transaction to update entitlements
                    await self.processTransaction(transaction)
                    
                } catch {
                    // Handle unverified transactions (e.g., log the error)
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    private func processTransaction(_ transaction: Transaction) async {
        // Only consider transactions for your products
        if productIDs.contains(transaction.productID) {
            
            // Check if the subscription is still active
            if transaction.revocationDate == nil {
                // Subscription is active or purchased
                purchasedProductIDs.insert(transaction.productID)
            } else {
                // Subscription has been refunded or revoked
                purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        // Always call finish() to remove the transaction from the queue
        await transaction.finish()
    }
    
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let unverifiedTransaction, let error):
            // The transaction failed verification. This is a security issue.
            throw error // Replace with a more robust error type if needed
        case .verified(let verifiedTransaction):
            return verifiedTransaction
        }
    }
    
    
    
    // Purchase a product
    func purchase(timeFrame: String) async {
            guard let productID = productID(for: timeFrame),
            let product = products.first(where: { $0.id == productID }) else {
                print("No product found for \(timeFrame)")
                return
            }
                    
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    // The purchase flow is complete. Now process the transaction!
                    await processTransaction(transaction)
                case .pending:
                    // Handle Ask-to-Buy or other pending states
                    print("Purchase is pending for parental approval.")
                case .userCancelled:
                    break // User closed the payment sheet
                @unknown default:
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
