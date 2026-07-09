import Foundation

/// A single financial transaction, as observed by the Finance Agent for
/// spend-anomaly detection. Amounts are in the user's local currency,
/// stored as minor units (cents) to avoid floating-point drift.
public struct FinanceTransaction: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let merchant: String
    public let amountCents: Int
    public let category: Category
    public let date: Date
    public let isAnomalous: Bool

    public init(
        id: UUID = UUID(),
        merchant: String,
        amountCents: Int,
        category: Category,
        date: Date,
        isAnomalous: Bool = false
    ) {
        self.id = id
        self.merchant = merchant
        self.amountCents = amountCents
        self.category = category
        self.date = date
        self.isAnomalous = isAnomalous
    }

    public enum Category: String, CaseIterable, Sendable {
        case dining
        case travel
        case shopping
        case subscriptions
        case transport
        case other
    }

    /// The transaction amount formatted for display, e.g. "$42.50".
    public var formattedAmount: String {
        let dollars = Double(amountCents) / 100
        return dollars.formatted(.currency(code: "USD"))
    }
}
