import Foundation

/// A single email message, as read from the user's inbox. Triage priority
/// is computed by the Email Agent, not stored here — this type only
/// carries what was observed.
public struct EmailMessage: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let sender: String
    public let subject: String
    public let preview: String
    public let receivedAt: Date
    public let isUnread: Bool
    public let requiresReply: Bool

    public init(
        id: UUID = UUID(),
        sender: String,
        subject: String,
        preview: String,
        receivedAt: Date,
        isUnread: Bool = true,
        requiresReply: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.subject = subject
        self.preview = preview
        self.receivedAt = receivedAt
        self.isUnread = isUnread
        self.requiresReply = requiresReply
    }
}
