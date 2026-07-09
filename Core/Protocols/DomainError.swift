/// Shared error type for domain-layer failures that don't warrant their
/// own dedicated error enum yet. Per docs/ENGINEERING_GUIDE.md's Error
/// Handling standard, feature-specific errors should graduate to their own
/// typed enum once they need to carry more than a message.
public enum DomainError: Error, Sendable {
    case notFound(String)
    case unavailable(String)
    case invalidState(String)
}
