/// Shared domain errors. Feature-specific errors may graduate to dedicated
/// enums once they need richer payloads (docs/ENGINEERING_GUIDE.md).
public enum DomainError: Error, Sendable, Equatable {
    case notFound
    case notFoundNamed(String)
    case unavailable
    case unavailableNamed(String)
    case unauthorized
    case unauthorizedNamed(String)
    case conflict
    case validationFailed(field: String)
    case invalidState(String)
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notFound:
            "The requested item could not be found."
        case let .notFoundNamed(name):
            "\(name) could not be found."
        case .unavailable:
            "This capability is currently unavailable."
        case let .unavailableNamed(reason):
            reason
        case .unauthorized:
            "This action is not authorized."
        case let .unauthorizedNamed(reason):
            reason
        case .conflict:
            "The approved parameters changed. Review and approve the action again."
        case let .validationFailed(field):
            "The \(field) value is missing or invalid."
        case let .invalidState(reason):
            reason
        }
    }
}
