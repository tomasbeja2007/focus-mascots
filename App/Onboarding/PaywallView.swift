import StoreKit
import SwiftUI

/// The end-of-onboarding "membership" screen.
///
/// While `Monetization.paywallEnabled` is false (today), it tells people that
/// everything is free and unlocks the full app. Flip the flag to show real
/// StoreKit products with purchase and restore buttons.
struct PaywallView: View {
    enum Context { case onboarding, settings }

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let mascot: Mascot
    var context: Context = .onboarding
    let onFinish: () -> Void

    @State private var selectedID: String = Monetization.yearlyID
    @State private var purchasing = false
    @State private var appeared = false

    private let features: [(String, String, String)] = [
        ("lock.shield.fill", "Unlimited app blocking", "Apps, categories and websites"),
        ("calendar.badge.clock", "Smart schedules", "Work, study and bedtime blocks"),
        ("person.3.fill", "The whole crew", "All five companions and their moods"),
        ("iphone.gen3.radiowaves.left.and.right", "Live Activities & widgets", "Lock Screen, Dynamic Island, Home Screen"),
        ("laptopcomputer", "Mac notch companion", "See your session next to the notch"),
        ("chart.bar.xaxis", "Insights & streaks", "Charts, badges and bond levels"),
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [mascot.wash, Theme.background], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            OnboardingPage {
                VStack(spacing: 18) {
                    HStack(alignment: .bottom, spacing: -24) {
                        ForEach(Array(crewOrder.enumerated()), id: \.offset) { index, m in
                            let isMain = m == mascot
                            MascotView(
                                mascot: m,
                                mood: isMain ? .excited : m.restingMood,
                                size: isMain ? 140 : (index == 0 || index == 4 ? 64 : 82),
                                showDecoration: isMain,
                                motion: .float
                            )
                            .zIndex(isMain ? 2 : (index == 1 || index == 3 ? 1 : 0))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text("Focus Crew")
                            .font(.rounded(size: 36, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        if Monetization.paywallEnabled && !model.purchases.hasPlus {
                            Text("Unlock everything and focus without limits.")
                                .font(.rounded(.body, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "gift.fill")
                                Text("Free during early access")
                            }
                            .font(.rounded(.subheadline, weight: .heavy))
                            .foregroundStyle(mascot.accent)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(mascot.tint))
                            Text("Every feature is unlocked. No trial, no card, no catch.")
                                .font(.rounded(.body, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, f in
                            HStack(spacing: 14) {
                                IconBadge(symbol: f.0, tint: mascot.accent, background: mascot.tint.opacity(0.6), size: 38)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.1).font(.rounded(.subheadline, weight: .bold)).foregroundStyle(Theme.ink)
                                    Text(f.2).font(.rounded(.footnote, weight: .medium)).foregroundStyle(Theme.inkSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.success)
                            }
                            .padding(.vertical, 10)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1 + Double(index) * 0.06), value: appeared)
                        }
                    }
                    .cardStyle(padding: 16, radius: Theme.cornerLarge)

                    if Monetization.paywallEnabled && !model.purchases.hasPlus {
                        planPicker
                    }
                }
            } footer: {
                if Monetization.paywallEnabled && !model.purchases.hasPlus {
                    Button {
                        Task { await buy() }
                    } label: {
                        if purchasing { ProgressView().tint(Theme.inkInverse) } else { Text(ctaTitle) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(purchasing || selectedProduct == nil)
                    HStack(spacing: 18) {
                        Button("Restore") { Task { await model.purchases.restore() } }
                        Link("Terms", destination: Monetization.termsURL)
                        Link("Privacy", destination: Monetization.privacyURL)
                    }
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                } else {
                    Button(context == .onboarding ? "Start focusing, it's free" : "Awesome") {
                        Haptics.success()
                        onFinish()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Text("You won't be charged. We'll always tell you before anything changes.")
                        .font(.rounded(.footnote))
                        .foregroundStyle(Theme.inkTertiary)
                        .multilineTextAlignment(.center)
                }
            }

            if context == .settings {
                CircleIconButton(symbol: "xmark", size: 34, label: "Close") { dismiss() }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            appeared = true
            Task { await model.purchases.loadProducts() }
        }
    }

    /// The whole crew with the user's companion in the middle.
    private var crewOrder: [Mascot] {
        var others = Mascot.allCases.filter { $0 != mascot }
        others.insert(mascot, at: 2)
        return others
    }

    private var selectedProduct: Product? {
        model.purchases.products.first { $0.id == selectedID }
    }

    private var ctaTitle: String {
        guard let p = selectedProduct else { return "Continue" }
        if p.subscription?.introductoryOffer != nil { return "Start free trial" }
        return "Continue for \(p.displayPrice)"
    }

    private var planPicker: some View {
        VStack(spacing: 10) {
            ForEach(model.purchases.products, id: \.id) { product in
                let selected = product.id == selectedID
                Button {
                    selectedID = product.id
                    Haptics.select()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName).font(.rounded(.headline, weight: .bold)).foregroundStyle(Theme.ink)
                            Text(product.description).font(.rounded(.footnote)).foregroundStyle(Theme.inkSecondary)
                        }
                        Spacer()
                        Text(product.displayPrice).font(.rounded(.headline, weight: .bold)).foregroundStyle(Theme.ink)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                            .strokeBorder(selected ? Theme.ink : Theme.hairline, lineWidth: selected ? 2 : 1)
                    )
                }
                .buttonStyle(PressableStyle())
            }
            if model.purchases.products.isEmpty {
                ProgressView().padding()
            }
        }
    }

    private func buy() async {
        guard let product = selectedProduct else { return }
        purchasing = true
        let ok = await model.purchases.purchase(product)
        purchasing = false
        if ok { onFinish() }
    }
}
