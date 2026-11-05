import Foundation
import Observation
import StoreKit

/// Monetisation switch.
///
/// Focus Crew is free for everyone right now: the paywall at the end of
/// onboarding only says so. To start charging later:
///   1. Create the products below in App Store Connect (same IDs, or change them here).
///   2. Set `paywallEnabled` to `true`.
/// Everything else (loading prices, purchasing, restoring, unlocking) is already wired up.
enum Monetization {
    static let paywallEnabled = false

    static let yearlyID = "com.focuscrew.plus.yearly"
    static let monthlyID = "com.focuscrew.plus.monthly"
    static let lifetimeID = "com.focuscrew.plus.lifetime"
    static let productIDs = [yearlyID, monthlyID, lifetimeID]

    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://tomasbeja2007.github.io/focus-mascots/privacy.html")!
    static let supportURL = URL(string: "https://tomasbeja2007.github.io/focus-mascots/support.html")!
    static let supportEmail = "support@focuscrew.app"
}

@MainActor
@Observable
final class PurchaseManager {
    private(set) var products: [Product] = []
    private(set) var purchasedIDs: Set<String> = []
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private var updates: Task<Void, Never>?

    /// Everything is unlocked while the paywall is switched off.
    var hasPlus: Bool { !Monetization.paywallEnabled || !purchasedIDs.isEmpty }

    func start() {
        guard Monetization.paywallEnabled else { return }
        updates?.cancel()
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        guard Monetization.paywallEnabled, products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: Monetization.productIDs)
            products = loaded.sorted { a, b in
                (Monetization.productIDs.firstIndex(of: a.id) ?? 0) < (Monetization.productIDs.firstIndex(of: b.id) ?? 0)
            }
        } catch {
            errorMessage = "Couldn't load prices. Check your connection and try again."
        }
    }

    func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil {
                ids.insert(t.productID)
            }
        }
        purchasedIDs = ids
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                }
                errorMessage = "The purchase couldn't be verified."
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Nothing to restore."
        }
    }
}
