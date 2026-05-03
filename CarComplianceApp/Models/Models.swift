import Foundation

// MARK: - Car

struct Car: Identifiable, Codable, Equatable {
    var id: Int64 = 0
    var nickname: String
    var make: String
    var model: String
    var year: Int
    var fuelType: FuelType
    var countryCode: String
    var lastServiceDate: Date?
    var insuranceExpiry: Date?
    var registrationExpiry: Date?
    var odometerKm: Int?
    var attachedDocumentPaths: [String] = []
    var createdAt: Date = Date()
}

enum FuelType: String, Codable, CaseIterable {
    case petrol = "PETROL"
    case diesel = "DIESEL"
    case electric = "ELECTRIC"
    case hybrid = "HYBRID"
    case lpg = "LPG"
    case unknown = "UNKNOWN"

    var displayName: String {
        switch self {
        case .petrol: return "Petrol"
        case .diesel: return "Diesel"
        case .electric: return "Electric"
        case .hybrid: return "Hybrid"
        case .lpg: return "LPG"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Task

struct ComplianceTask: Identifiable, Codable, Equatable {
    var id: Int64 = 0
    var carId: Int64
    var title: String
    var category: TaskCategory
    var dueDate: Date?
    var dueDateWindow: String
    var status: TaskStatus
    var urgency: UrgencyLevel
    var why: String
    var isUserEditable: Bool = true
    var isUserOverride: Bool = false
    var snoozedUntil: Date?
    var completedAt: Date?
    var createdAt: Date = Date()
}

enum TaskCategory: String, Codable, CaseIterable {
    case legal = "LEGAL"
    case maintenance = "MAINTENANCE"
    case insurance = "INSURANCE"
    case documentation = "DOCUMENTATION"

    var displayName: String {
        switch self {
        case .legal: return "Legal"
        case .maintenance: return "Maintenance"
        case .insurance: return "Insurance"
        case .documentation: return "Documentation"
        }
    }
}

enum TaskStatus: String, Codable {
    case upcoming = "UPCOMING"
    case overdue = "OVERDUE"
    case done = "DONE"
    case snoozed = "SNOOZED"
}

enum UrgencyLevel: String, Codable, Comparable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"

    private var order: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool { lhs.order < rhs.order }
}

// MARK: - API Key

enum AiProvider: String, Codable, CaseIterable {
    case openai = "OPENAI"
    case anthropic = "ANTHROPIC"
    case google = "GOOGLE"
    case mistral = "MISTRAL"
    case cohere = "COHERE"

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google Gemini"
        case .mistral: return "Mistral AI"
        case .cohere: return "Cohere"
        }
    }

    var baseUrl: String {
        switch self {
        case .openai: return "https://api.openai.com/"
        case .anthropic: return "https://api.anthropic.com/"
        case .google: return "https://generativelanguage.googleapis.com/"
        case .mistral: return "https://api.mistral.ai/"
        case .cohere: return "https://api.cohere.com/"
        }
    }
}

struct ApiKeyConfig: Codable {
    var rawKey: String
    var provider: AiProvider
    var isValid: Bool = true
}

// MARK: - Notifications

struct NotificationPreferences: Codable {
    var thirtyDays: Bool = true
    var sevenDays: Bool = true
    var oneDay: Bool = true
}

// MARK: - AI task (raw from API)

struct AiTask: Codable {
    let title: String
    let category: String
    let dueDateWindow: String
    let urgency: String
    let why: String
    let dueDate: String?
}
