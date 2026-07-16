import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Explicit preferences, routines, places, and corrections — never silent memory.
public struct MemoryView: View {
    @State private var viewModel: MemoryViewModel

    public init(preferenceStore: any PreferenceStore) {
        _viewModel = State(initialValue: MemoryViewModel(preferenceStore: preferenceStore))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Title", text: $viewModel.draftTitle)
                    .textFieldStyle(.roundedBorder)
                Picker("Kind", selection: $viewModel.draftKind) {
                    ForEach(MemoryItem.Kind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                Button("Add") {
                    Task { try? await viewModel.addDraft() }
                }
                .disabled(viewModel.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(Spacing.lg)

            if viewModel.items.isEmpty {
                EmptyStateView(
                    symbolName: "brain.head.profile",
                    message: "Save preferences, routines, places, and corrections you choose — "
                        + "LifePilot never promotes a one-off action into permanent memory."
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.LifePilot.body)
                                if item.isPinned {
                                    Image(systemName: "pin.fill")
                                        .foregroundStyle(Color.LifePilot.accentEnd)
                                }
                            }
                            Text(item.kind.rawValue)
                                .font(.LifePilot.caption)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                            if let detail = item.detail {
                                Text(detail)
                                    .font(.LifePilot.caption)
                                    .foregroundStyle(Color.LifePilot.textSecondary)
                            }
                            Text("Provenance: \(item.provenance)")
                                .font(.caption2)
                                .foregroundStyle(Color.LifePilot.textSecondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { try? await viewModel.forget(item) }
                            } label: {
                                Label("Forget", systemImage: "trash")
                            }
                            Button {
                                Task { try? await viewModel.togglePin(item) }
                            } label: {
                                Label(item.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Memory")
        .task { await viewModel.load() }
    }
}

@Observable
@MainActor
public final class MemoryViewModel {
    public private(set) var items: [MemoryItem] = []
    public var draftTitle = ""
    public var draftKind: MemoryItem.Kind = .preference

    private let preferenceStore: any PreferenceStore

    public init(preferenceStore: any PreferenceStore) {
        self.preferenceStore = preferenceStore
    }

    public func load() async {
        items = await preferenceStore.allMemory()
    }

    public func addDraft() async throws {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let item = MemoryItem(
            kind: draftKind,
            title: title,
            provenance: "Explicit user entry"
        )
        try await preferenceStore.saveMemory(item)
        draftTitle = ""
        await load()
    }

    public func forget(_ item: MemoryItem) async throws {
        try await preferenceStore.deleteMemory(id: item.id)
        await load()
    }

    public func togglePin(_ item: MemoryItem) async throws {
        var updated = item
        updated.isPinned.toggle()
        updated.updatedAt = Date()
        try await preferenceStore.saveMemory(updated)
        await load()
    }
}
