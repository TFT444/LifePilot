import Foundation
import LifePilotCore

/// Realistic sample transaction data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockFinance {
    public static func transactions(relativeTo now: Date = Date()) -> [FinanceTransaction] {
        [
            FinanceTransaction(
                merchant: "Tatte Bakery",
                amountCents: 1850,
                category: .dining,
                date: now.addingTimeInterval(-18 * 3600)
            ),
            FinanceTransaction(
                merchant: "United Airlines",
                amountCents: 48_200,
                category: .travel,
                date: now.addingTimeInterval(-3 * 24 * 3600)
            ),
            FinanceTransaction(
                merchant: "Unfamiliar Merchant #4471",
                amountCents: 34_000,
                category: .other,
                date: now.addingTimeInterval(-2 * 3600),
                isAnomalous: true
            ),
            FinanceTransaction(
                merchant: "Cloud Hosting Co.",
                amountCents: 2900,
                category: .subscriptions,
                date: now.addingTimeInterval(-5 * 24 * 3600)
            ),
        ]
    }
}
