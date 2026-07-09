import LifePilotDesignSystem
import SwiftUI

/// The Settings screen. Placeholder rows only in this phase — see
/// `SettingsViewModel`.
public struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(section.title) {
                    ForEach(section.rows) { row in
                        HStack(spacing: Spacing.md) {
                            Image(systemName: row.symbolName)
                                .foregroundStyle(LinearGradient.LifePilot.accent)
                                .frame(width: 24)

                            Text(row.title)
                                .font(.LifePilot.body)
                                .foregroundStyle(Color.LifePilot.textPrimary)

                            Spacer()

                            if let detail = row.detail {
                                Text(detail)
                                    .font(.LifePilot.caption)
                                    .foregroundStyle(Color.LifePilot.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
