import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case models = "Models"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .models: return "cpu"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @Bindable var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 22, height: 22)
                        .background(Theme.bgHover)
                        .cornerRadius(6)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bgHeader)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        SettingsTabRow(tab: tab, isSelected: selectedTab == tab)
                            .onTapGesture { selectedTab = tab }
                    }
                    Spacer()
                }
                .padding(12)
                .frame(width: 180)
                .background(Theme.bgSidebar)

            Rectangle()
                .fill(Theme.border)
                .frame(width: 1)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsContent(settings: settings)
                    case .models:
                        ModelsSettingsContent(settings: settings)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.bg)
            }
        }
        .frame(width: 860, height: 580)
        .background(Theme.bg)
    }
}

// MARK: - Sidebar Tab Row

private struct SettingsTabRow: View {
    let tab: SettingsTab
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tab.icon)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .frame(width: 18)
            Text(tab.rawValue)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? Theme.accent.opacity(0.2) : isHovered ? Theme.bgHover : .clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - General Settings

private struct GeneralSettingsContent: View {
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section: API Keys
            SectionHeader(title: "API Keys")

            APIKeyField(
                label: "Anthropic API Key",
                placeholder: "sk-ant-...",
                value: $settings.anthropicAPIKey
            )

            APIKeyField(
                label: "Google API Key",
                placeholder: "AIza...",
                value: $settings.googleAPIKey
            )
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.bottom, 4)
    }
}

private struct APIKeyField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                Group {
                    if isRevealed {
                        TextField(placeholder, text: $value)
                    } else {
                        SecureField(placeholder, text: $value)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.bgSidebar)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.border, lineWidth: 1)
                )

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
            }

            if !value.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(nsColor: .init(srgbRed: 0.337, green: 0.804, blue: 0.478, alpha: 1)))
                    Text("Key saved")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
}

// MARK: - Models Settings

private struct ModelsSettingsContent: View {
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Anthropic Models
            SectionHeader(title: "Anthropic Models")

            VStack(spacing: 2) {
                ForEach(AIModel.anthropicModels) { model in
                    ModelRow(model: model, settings: settings)
                }
            }

            if settings.anthropicAPIKey.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("Add your Anthropic API key in General settings")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Divider()
                .background(Theme.border)

            // Google Models
            SectionHeader(title: "Google Models")

            VStack(spacing: 2) {
                ForEach(AIModel.googleModels) { model in
                    ModelRow(model: model, settings: settings)
                }
            }

            if settings.googleAPIKey.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("Add your Google API key in General settings")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
}

private struct ModelRow: View {
    let model: AIModel
    @Bindable var settings: AppSettings
    @State private var isHovered = false

    private var isEnabled: Bool {
        settings.isModelEnabled(model.id)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Image(systemName: isEnabled ? "checkmark.square.fill" : "square")
                .font(.system(size: 15))
                .foregroundStyle(isEnabled ? Theme.accent : Theme.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isEnabled ? Theme.textPrimary : Theme.textSecondary)
                Text(model.description)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            Text(model.id)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.textMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.bgHover : .clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            settings.toggleModel(model.id)
        }
    }
}
