//
//  SubscriptionManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 10/30/25.
//

import Foundation
import StoreKit
import RevenueCat

enum SubscriptionManager {
    static let entitlementID = "Premium Subscription"

    static func isSubscribed() async -> Bool {
        do {
            let info = try await Purchases.shared.customerInfo()
            return info.entitlements[entitlementID]?.isActive == true
        } catch {
            Log.app.error("❌ Error checking subscription: \(error.localizedDescription, privacy: .private)")
            return false
        }
    }
}
