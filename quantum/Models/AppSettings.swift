import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var anthropicAPIKey: String {
        didSet { save("anthropicAPIKey", anthropicAPIKey) }
    }
    var googleAPIKey: String {
        didSet { save("googleAPIKey", googleAPIKey) }
    }
    var enabledModels: Set<String> {
        didSet { UserDefaults.standard.set(Array(enabledModels), forKey: "enabledModels") }
    }
    var lastSelectedModelID: String {
        didSet { save("lastSelectedModelID", lastSelectedModelID) }
    }

    private init() {
        self.anthropicAPIKey = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
        self.googleAPIKey = UserDefaults.standard.string(forKey: "googleAPIKey") ?? ""
        let saved = UserDefaults.standard.stringArray(forKey: "enabledModels")
        self.enabledModels = Set(saved ?? AIModel.allModels.map(\.id))
        self.lastSelectedModelID = UserDefaults.standard.string(forKey: "lastSelectedModelID") ?? ""
    }

    private func save(_ key: String, _ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func isModelEnabled(_ id: String) -> Bool {
        enabledModels.contains(id)
    }

    func toggleModel(_ id: String) {
        if enabledModels.contains(id) {
            enabledModels.remove(id)
        } else {
            enabledModels.insert(id)
        }
    }

    /// Models that are enabled AND have a valid API key
    var availableModels: [AIModel] {
        AIModel.allModels.filter { model in
            guard enabledModels.contains(model.id) else { return false }
            switch model.provider {
            case .anthropic: return !anthropicAPIKey.isEmpty
            case .google: return !googleAPIKey.isEmpty
            }
        }
    }

    /// Resolved model ID: last selected if still available, otherwise first available
    var resolvedModelID: String {
        let available = availableModels
        if !lastSelectedModelID.isEmpty, available.contains(where: { $0.id == lastSelectedModelID }) {
            return lastSelectedModelID
        }
        return available.first?.id ?? ""
    }
}

// MARK: - AI Models

struct AIModel: Identifiable {
    let id: String
    let name: String
    let provider: AIProvider
    let description: String

    enum AIProvider: String, CaseIterable {
        case anthropic = "Anthropic"
        case google = "Google"
    }

    static let allModels: [AIModel] = [
        // Anthropic
        AIModel(id: "claude-opus-4-6", name: "Claude Opus", provider: .anthropic, description: "Most capable, best for complex tasks"),
        AIModel(id: "claude-sonnet-4-5-latest", name: "Claude Sonnet", provider: .anthropic, description: "Fast and balanced"),
        AIModel(id: "claude-haiku-4-5-latest", name: "Claude Haiku", provider: .anthropic, description: "Fastest, lightweight tasks"),
        // Google
        AIModel(id: "gemini-2.5-pro", name: "Gemini 2.5 Pro", provider: .google, description: "Most capable Google model"),
        AIModel(id: "gemini-2.5-flash", name: "Gemini 2.5 Flash", provider: .google, description: "Fast and efficient"),
        AIModel(id: "gemini-2.0-flash", name: "Gemini 2.0 Flash", provider: .google, description: "Previous gen, very fast"),
    ]

    static var anthropicModels: [AIModel] {
        allModels.filter { $0.provider == .anthropic }
    }

    static var googleModels: [AIModel] {
        allModels.filter { $0.provider == .google }
    }
}
