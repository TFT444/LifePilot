import LifePilotDesignSystem
import SwiftUI

/// Placeholder for the Memory tab — the user-visible surface for
/// LifePilot's long-term preferences and history, per README.md's Memory
/// feature description. Full implementation arrives in
/// docs/MASTER_ROADMAP.md Phase 4.
public struct MemoryView: View {
    public init() {}

    public var body: some View {
        ComingSoonPlaceholder(
            symbolName: "brain.head.profile",
            title: "Memory",
            message: "LifePilot will remember your preferences, routines, and relationships here."
        )
        .navigationTitle("Memory")
    }
}

#Preview {
    NavigationStack {
        MemoryView()
    }
}
