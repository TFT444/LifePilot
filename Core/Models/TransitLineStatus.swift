import Foundation

/// The current service status of a transit line (e.g. a Tube line), normalised
/// from a provider feed. Drives the disruption banners and "reroute" reasoning
/// the Travel Agent surfaces to Ghost Brain.
public struct TransitLineStatus: Identifiable, Hashable, Sendable {
    public var id: String { lineName }
    public let lineName: String
    public let statusDescription: String
    public let severity: Severity

    public init(lineName: String, statusDescription: String, severity: Severity) {
        self.lineName = lineName
        self.statusDescription = statusDescription
        self.severity = severity
    }

    /// Whether this line is running normally.
    public var isGoodService: Bool { severity == .good }

    public enum Severity: String, Comparable, CaseIterable, Sendable {
        case good
        case minor
        case severe

        private var order: Int {
            switch self {
            case .good: return 0
            case .minor: return 1
            case .severe: return 2
            }
        }

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.order < rhs.order
        }

        /// Classifies a provider's free-text status into a severity bucket.
        /// TfL, for example, uses "Good Service", "Minor Delays",
        /// "Severe Delays", "Part Suspended", etc.
        public static func classify(_ description: String) -> Severity {
            let text = description.lowercased()
            if text == "good service" {
                return .good
            }
            if text.contains("minor") {
                return .minor
            }
            return .severe
        }
    }
}
