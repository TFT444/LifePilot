import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Explicit preferences, routines, places, and corrections — never silent memory.
public struct MemoryView: View {
    @State private var viewModel: MemoryViewModel
    @State private var isAdding = false

    public init(preferenceStore: any PreferenceStore) {
        _viewModel = State(initialValue: MemoryViewModel(preferenceStore: preferenceStore))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                InsightHero(
                    title: "Your rulebook",
                    detail: "Only preferences you add or confirm become permanent Memory."
                )
                filterBar
                content
            }
            .padding(Spacing.lg)
        }
        .background(AmbientBackground())
        .navigationTitle("Memory")
        .task { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAdding = true
                } label: {
                    Label("Add Memory", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAdding) {
            NavigationStack {
                memoryComposer
                    .navigationTitle("Add Memory")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isAdding = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task {
                                    try? await viewModel.addDraft()
                                    isAdding = false
                                }
                            }
                            .disabled(
                                viewModel.draftTitle
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                            )
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedKind == nil,
                    action: { viewModel.setKind(nil) }
                )
                ForEach(MemoryItem.Kind.allCases, id: \.self) { kind in
                    FilterChip(
                        title: kind.rawValue.capitalized,
                        isSelected: viewModel.selectedKind == kind,
                        action: { viewModel.setKind(kind) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.filteredItems.isEmpty {
            EmptyStateView(
                symbolName: "brain.head.profile",
                message: "Nothing saved in this category. Add a preference, routine, "
                    + "place, or correction when it becomes useful."
            )
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if !viewModel.pinnedItems.isEmpty {
                    SectionHeader(title: "Pinned", symbolName: "pin.fill")
                    ForEach(viewModel.pinnedItems) { item in
                        memoryRow(item)
                    }
                }
                SectionHeader(title: "Memory", symbolName: "brain.head.profile")
                ForEach(viewModel.unpinnedItems) { item in
                    memoryRow(item)
                }
            }
        }
    }

    private func memoryRow(_ item: MemoryItem) -> some View {
        GlowCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: symbol(for: item.kind))
                    .foregroundStyle(Color.LifePilot.accentTeal)
                    .frame(width: IconSize.md)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.title)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text(item.kind.rawValue.capitalized)
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.accentEnd)
                    if let detail = item.detail {
                        Text(detail)
                            .font(.LifePilot.caption)
                            .foregroundStyle(Color.LifePilot.textSecondary)
                    }
                    Label(item.provenance, systemImage: "checkmark.seal")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                Spacer()
                Menu {
                    Button(item.isPinned ? "Unpin" : "Pin") {
                        Task { try? await viewModel.togglePin(item) }
                    }
                    Button("Forget", role: .destructive) {
                        Task { try? await viewModel.forget(item) }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: 44, height: 44)
                }
            }
        }
    }

    private var memoryComposer: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Memory stays visible and reversible. One-off actions are never learned.")
                .font(.LifePilot.body)
                .foregroundStyle(Color.LifePilot.textSecondary)
            TextField("What should LifePilot remember?", text: $viewModel.draftTitle)
                .lifePilotField()
            Picker("Kind", selection: $viewModel.draftKind) {
                ForEach(MemoryItem.Kind.allCases, id: \.self) { kind in
                    Text(kind.rawValue.capitalized).tag(kind)
                }
            }
            .pickerStyle(.menu)
            Spacer()
        }
        .padding(Spacing.lg)
        .background(AmbientBackground())
    }

    private func symbol(for kind: MemoryItem.Kind) -> String {
        switch kind {
        case .preference: "slider.horizontal.3"
        case .routine: "repeat"
        case .place: "mappin.and.ellipse"
        case .person: "person.fill"
        case .workPattern: "briefcase.fill"
        case .travelBuffer: "car.fill"
        case .quietHours: "moon.fill"
        case .correction: "arrow.uturn.backward"
        }
    }
}

@Observable
@MainActor
public final class MemoryViewModel {
    public private(set) var items: [MemoryItem] = []
    public private(set) var selectedKind: MemoryItem.Kind?
    public var draftTitle = ""
    public var draftKind: MemoryItem.Kind = .preference

    private let preferenceStore: any PreferenceStore

    public init(preferenceStore: any PreferenceStore) {
        self.preferenceStore = preferenceStore
    }

    public var filteredItems: [MemoryItem] {
        guard let selectedKind else { return items }
        return items.filter { $0.kind == selectedKind }
    }

    public var pinnedItems: [MemoryItem] {
        filteredItems.filter(\.isPinned)
    }

    public var unpinnedItems: [MemoryItem] {
        filteredItems.filter { !$0.isPinned }
    }

    public func setKind(_ kind: MemoryItem.Kind?) {
        selectedKind = kind
    }

    public func load() async {
        items = await preferenceStore.allMemory()
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned
                }
                return lhs.updatedAt > rhs.updatedAt
            }
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
