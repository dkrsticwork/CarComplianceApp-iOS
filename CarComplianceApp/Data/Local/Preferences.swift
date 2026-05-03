import Foundation
import Combine

final class Preferences: ObservableObject {
    static let shared = Preferences()

    @Published var onboardingDone: Bool {
        didSet { UserDefaults.standard.set(onboardingDone, forKey: "onboarding_done") }
    }

    @Published var activeCarId: Int64? {
        didSet {
            if let v = activeCarId {
                UserDefaults.standard.set(v, forKey: "active_car_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "active_car_id")
            }
        }
    }

    @Published var apiKeyConfig: ApiKeyConfig? {
        didSet {
            if let v = apiKeyConfig, let data = try? JSONEncoder().encode(v) {
                UserDefaults.standard.set(data, forKey: "api_key_config")
            } else {
                UserDefaults.standard.removeObject(forKey: "api_key_config")
            }
        }
    }

    @Published var notificationPrefs: NotificationPreferences {
        didSet {
            if let data = try? JSONEncoder().encode(notificationPrefs) {
                UserDefaults.standard.set(data, forKey: "notif_prefs")
            }
        }
    }

    @Published var lastApiError: String? {
        didSet { UserDefaults.standard.set(lastApiError, forKey: "last_api_error") }
    }

    private init() {
        onboardingDone = UserDefaults.standard.bool(forKey: "onboarding_done")

        if UserDefaults.standard.object(forKey: "active_car_id") != nil {
            activeCarId = Int64(bitPattern: UInt64(bitPattern: UserDefaults.standard.integer(forKey: "active_car_id")))
        } else {
            activeCarId = nil
        }

        if let data = UserDefaults.standard.data(forKey: "api_key_config") {
            apiKeyConfig = try? JSONDecoder().decode(ApiKeyConfig.self, from: data)
        } else {
            apiKeyConfig = nil
        }

        if let data = UserDefaults.standard.data(forKey: "notif_prefs"),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            notificationPrefs = prefs
        } else {
            notificationPrefs = NotificationPreferences()
        }

        lastApiError = UserDefaults.standard.string(forKey: "last_api_error")
    }

    func detectProvider(_ key: String) -> AiProvider {
        if key.hasPrefix("sk-ant-") { return .anthropic }
        if key.hasPrefix("sk-") && key.count > 40 { return .openai }
        if key.hasPrefix("AIza") { return .google }
        if key.hasPrefix("mis") { return .mistral }
        return .cohere
    }

    func saveActiveCarId(_ id: Int64) {
        UserDefaults.standard.set(Int(id), forKey: "active_car_id")
        activeCarId = id
    }

    func clearApiError() {
        lastApiError = nil
        UserDefaults.standard.removeObject(forKey: "last_api_error")
    }
}
