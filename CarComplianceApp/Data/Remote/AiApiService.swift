import Foundation

// MARK: - Result type

enum AiResult {
    case success([AiTask])
    case failure(String)
}

// MARK: - Service

final class AiApiService {
    static let shared = AiApiService()
    private init() {}

    func generateComplianceTasks(car: Car, config: ApiKeyConfig) async -> AiResult {
        let prompt = buildPrompt(car: car)
        do {
            let content: String
            switch config.provider {
            case .openai:    content = try await callOpenAI(key: config.rawKey, prompt: prompt)
            case .anthropic: content = try await callAnthropic(key: config.rawKey, prompt: prompt)
            case .google:    content = try await callGoogle(key: config.rawKey, prompt: prompt)
            case .mistral:   content = try await callMistral(key: config.rawKey, prompt: prompt)
            case .cohere:    content = try await callCohere(key: config.rawKey, prompt: prompt)
            }
            return parseTasks(from: content)
        } catch {
            return .failure("Network error: \(error.localizedDescription). Your saved tasks are still available.")
        }
    }

    // MARK: - Prompt

    private func buildPrompt(car: Car) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let today = df.string(from: Date())
        let lastService = car.lastServiceDate.map { df.string(from: $0) } ?? "unknown"
        let insurance = car.insuranceExpiry.map { df.string(from: $0) } ?? "unknown"
        let registration = car.registrationExpiry.map { df.string(from: $0) } ?? "unknown"
        let odometer = car.odometerKm.map { "\($0) km" } ?? "unknown"

        return """
You are a car compliance expert. Generate a personalized obligation list for this car owner.

TODAY: \(today)

CAR:
- Make/Model: \(car.make) \(car.model)
- Year: \(car.year)
- Fuel: \(car.fuelType.displayName)
- Country: \(car.countryCode)
- Last service: \(lastService)
- Insurance expiry: \(insurance)
- Registration expiry: \(registration)
- Odometer: \(odometer)

Generate 4-8 compliance tasks covering legal, insurance, maintenance, and documentation obligations specific to \(car.countryCode).

RULES:
- Urgency: CRITICAL=overdue, HIGH=within 7 days, MEDIUM=within 30 days, LOW=future
- Category: one of LEGAL, MAINTENANCE, INSURANCE, DOCUMENTATION
- Each task MUST include a clear "why" explanation (1-2 sentences)
- Never fabricate specific legal deadlines you don't know for certain

Respond ONLY with a valid JSON array. No preamble, no markdown.

Format:
[{"title":"...","category":"LEGAL","dueDate":"2025-06-15","dueDateWindow":"June 2025","urgency":"MEDIUM","why":"..."}]
"""
    }

    // MARK: - Provider calls

    private func callOpenAI(key: String, prompt: String) async throws -> String {
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a car compliance expert. Always respond with valid JSON only."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 2000,
            "temperature": 0.2
        ]
        let data = try await post(
            url: "https://api.openai.com/v1/chat/completions",
            body: body,
            headers: ["Authorization": "Bearer \(key)"]
        )
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let choices = json["choices"] as! [[String: Any]]
        let message = choices[0]["message"] as! [String: Any]
        return message["content"] as! String
    }

    private func callAnthropic(key: String, prompt: String) async throws -> String {
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 2000,
            "system": "You are a car compliance expert. Always respond with valid JSON only.",
            "messages": [["role": "user", "content": prompt]]
        ]
        let data = try await post(
            url: "https://api.anthropic.com/v1/messages",
            body: body,
            headers: [
                "x-api-key": key,
                "anthropic-version": "2023-06-01"
            ]
        )
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let content = json["content"] as! [[String: Any]]
        return content[0]["text"] as! String
    }

    private func callGoogle(key: String, prompt: String) async throws -> String {
        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.2, "maxOutputTokens": 2000]
        ]
        let data = try await post(
            url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(key)",
            body: body,
            headers: [:]
        )
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let candidates = json["candidates"] as! [[String: Any]]
        let content = candidates[0]["content"] as! [String: Any]
        let parts = content["parts"] as! [[String: Any]]
        return parts[0]["text"] as! String
    }

    private func callMistral(key: String, prompt: String) async throws -> String {
        let body: [String: Any] = [
            "model": "mistral-small-latest",
            "messages": [
                ["role": "system", "content": "You are a car compliance expert. Always respond with valid JSON only."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 2000,
            "temperature": 0.2
        ]
        let data = try await post(
            url: "https://api.mistral.ai/v1/chat/completions",
            body: body,
            headers: ["Authorization": "Bearer \(key)"]
        )
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let choices = json["choices"] as! [[String: Any]]
        let message = choices[0]["message"] as! [String: Any]
        return message["content"] as! String
    }

    private func callCohere(key: String, prompt: String) async throws -> String {
        let body: [String: Any] = [
            "model": "command-r-plus",
            "message": prompt,
            "preamble": "You are a car compliance expert. Always respond with valid JSON only.",
            "temperature": 0.2
        ]
        let data = try await post(
            url: "https://api.cohere.com/v1/chat",
            body: body,
            headers: ["Authorization": "Bearer \(key)"]
        )
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json["text"] as! String
    }

    // MARK: - HTTP

    private func post(url urlString: String, body: [String: Any], headers: [String: String]) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    // MARK: - Parse

    private func parseTasks(from content: String) -> AiResult {
        var cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = cleaned.firstIndex(of: "["),
           let end = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[start...end])
        }

        guard let data = cleaned.data(using: .utf8),
              let tasks = try? JSONDecoder().decode([AiTask].self, from: data) else {
            return .failure("AI responded but the response couldn't be parsed. Your saved tasks are still available.")
        }
        return .success(tasks)
    }
}

// MARK: - AiTask -> ComplianceTask

extension AiTask {
    func toComplianceTask(carId: Int64) -> ComplianceTask {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let due = dueDate.flatMap { df.date(from: $0) }

        let cat: TaskCategory
        switch category.uppercased() {
        case "LEGAL":         cat = .legal
        case "MAINTENANCE":   cat = .maintenance
        case "INSURANCE":     cat = .insurance
        case "DOCUMENTATION": cat = .documentation
        default:              cat = .legal
        }

        let urg: UrgencyLevel
        switch urgency.uppercased() {
        case "CRITICAL": urg = .critical
        case "HIGH":     urg = .high
        case "MEDIUM":   urg = .medium
        default:         urg = .low
        }

        let today = Date()
        let status: TaskStatus = (due != nil && due! < today) ? .overdue : .upcoming

        return ComplianceTask(
            carId: carId,
            title: title,
            category: cat,
            dueDate: due,
            dueDateWindow: dueDateWindow,
            status: status,
            urgency: urg,
            why: why
        )
    }
}
