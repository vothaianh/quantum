import Foundation

enum AIService {

    struct EditRequest {
        let fullContent: String
        let selectedText: String
        let fromLine: Int
        let toLine: Int
        let fileExtension: String
        let userPrompt: String
        let modelID: String
    }

    static func performEdit(_ request: EditRequest) async throws -> String {
        guard let model = AIModel.allModels.first(where: { $0.id == request.modelID }) else {
            throw AIError.invalidModel
        }

        let prompt = buildPrompt(request)

        switch model.provider {
        case .anthropic:
            return try await callAnthropic(prompt: prompt, modelID: request.modelID)
        case .google:
            return try await callGoogle(prompt: prompt, modelID: request.modelID)
        }
    }

    static func generateCommitMessage(diff: String, modelID: String) async throws -> String {
        guard let model = AIModel.allModels.first(where: { $0.id == modelID }) else {
            throw AIError.invalidModel
        }

        // Truncate diff to avoid token limits
        let maxLen = 12000
        let truncatedDiff = diff.count > maxLen ? String(diff.prefix(maxLen)) + "\n... (truncated)" : diff

        let prompt = """
        Generate a concise git commit message for the following changes. \
        Use conventional commit format (e.g. feat:, fix:, refactor:, chore:, docs:, style:). \
        Keep it to 1 line, max 72 characters. No quotes, no explanation, just the message.

        Diff:
        \(truncatedDiff)
        """

        switch model.provider {
        case .anthropic:
            return try await callAnthropic(prompt: prompt, modelID: modelID)
        case .google:
            return try await callGoogle(prompt: prompt, modelID: modelID)
        }
    }

    // MARK: - Prompt

    private static func buildPrompt(_ req: EditRequest) -> String {
        """
        You are a code editor assistant. The user has a file and has selected some code they want you to modify.

        Full file content:
        ```\(req.fileExtension)
        \(req.fullContent)
        ```

        Selected code (line \(req.fromLine + 1) to \(req.toLine + 1)):
        ```
        \(req.selectedText)
        ```

        User request: \(req.userPrompt)

        Respond with ONLY the replacement code for the selected portion. No explanations, no markdown fences, no extra text.
        """
    }

    // MARK: - Anthropic

    private static func callAnthropic(prompt: String, modelID: String) async throws -> String {
        let apiKey = AppSettings.shared.anthropicAPIKey
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey("Anthropic") }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 4096,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid response")
        }
        guard http.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(http.statusCode, errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw AIError.parseError
        }

        return text
    }

    // MARK: - Google

    private static func callGoogle(prompt: String, modelID: String) async throws -> String {
        let apiKey = AppSettings.shared.googleAPIKey
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey("Google") }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelID):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw AIError.networkError("Invalid URL") }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid response")
        }
        guard http.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(http.statusCode, errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIError.parseError
        }

        return text
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case invalidModel
    case missingAPIKey(String)
    case networkError(String)
    case apiError(Int, String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidModel: return "Invalid model selected"
        case .missingAPIKey(let provider): return "Missing \(provider) API key. Add it in Settings."
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let code, let body): return "API error (\(code)): \(body)"
        case .parseError: return "Failed to parse API response"
        }
    }
}
