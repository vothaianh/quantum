import SwiftUI

/// Data sent from CodeMirror when user presses Cmd+K
struct AIEditRequest {
    let selectedText: String
    let fullContent: String
    let fromLine: Int
    let fromCh: Int
    let toLine: Int
    let toCh: Int
    let fileExtension: String
}

struct AIEditPopupView: View {
    let request: AIEditRequest
    let onSubmit: (String, String) -> Void  // (modelID, prompt)
    let onCancel: () -> Void

    @State private var prompt = ""
    @State private var selectedModelID = AppSettings.shared.resolvedModelID
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isPromptFocused: Bool

    private var settings: AppSettings { AppSettings.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text("AI Edit")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("⌘K")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Theme.bgHover)
                    .cornerRadius(3)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            // Selection preview
            ScrollView {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                        .padding(.top, 2)
                    Text(selectionPreview)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            // Prompt input (multiline)
            TextEditor(text: $prompt)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isPromptFocused)
                .frame(minHeight: 90, maxHeight: 160)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("Describe the edit...")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            // Model picker + submit
            HStack(spacing: 8) {
                Picker("", selection: $selectedModelID) {
                    ForEach(settings.availableModels) { model in
                        Text(model.name)
                            .tag(model.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)
                .labelsHidden()

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                } else {
                    Button(action: submit) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 14))
                            Text("Submit ⌘↩")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            prompt.isEmpty || selectedModelID.isEmpty
                                ? Theme.textMuted : Theme.accent
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                    .disabled(prompt.isEmpty || selectedModelID.isEmpty || isLoading)
                    .help("Submit AI edit request (\u{2318}\u{21A9})")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Error message
            if let error = errorMessage {
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 480)
        .background(Theme.bgHeader)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        .onAppear { isPromptFocused = true }
        .background {
            Button("") { submit() }
                .keyboardShortcut(.return, modifiers: .command)
                .hidden()
        }
    }

    private var selectionPreview: String {
        let text = request.selectedText
        if text.isEmpty { return "No selection" }
        let words = text.split(separator: " ", maxSplits: 300, omittingEmptySubsequences: true)
        if words.count > 300 {
            return words.prefix(300).joined(separator: " ") + "..."
        }
        return text
    }

    private func submit() {
        guard !prompt.isEmpty, !selectedModelID.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil

        // Persist model selection
        AppSettings.shared.lastSelectedModelID = selectedModelID

        let editRequest = AIService.EditRequest(
            fullContent: request.fullContent,
            selectedText: request.selectedText,
            fromLine: request.fromLine,
            toLine: request.toLine,
            fileExtension: request.fileExtension,
            userPrompt: prompt,
            modelID: selectedModelID
        )

        Task {
            do {
                let result = try await AIService.performEdit(editRequest)
                await MainActor.run {
                    onSubmit(selectedModelID, result)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
