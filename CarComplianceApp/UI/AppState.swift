import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: - Stores
    let carStore = CarStore()
    let taskStore = TaskStore()
    let prefs = Preferences.shared

    // MARK: - Published UI state
    @Published var activeCarId: Int64?
    @Published var isRefreshing = false
    @Published var lastApiError: String?

    // MARK: - Computed
    var cars: [Car] { carStore.cars }

    var activeCar: Car? {
        if let id = activeCarId { return carStore.cars.first { $0.id == id } }
        return carStore.cars.first
    }

    var tasks: [ComplianceTask] {
        guard let car = activeCar else { return [] }
        return taskStore.tasks(for: car.id).sorted { $0.urgency < $1.urgency }
    }

    // MARK: - Init
    init() {
        activeCarId = prefs.activeCarId
        lastApiError = prefs.lastApiError
        NotificationScheduler.shared.requestPermission()
    }

    // MARK: - Car actions

    func saveCar(_ car: Car, apiConfig: ApiKeyConfig?) async {
        let saved = carStore.insert(car)
        activeCarId = saved.id
        prefs.saveActiveCarId(saved.id)
        prefs.onboardingDone = true

        if let config = apiConfig {
            await generateTasks(for: saved, config: config)
        } else {
            taskStore.insertAll(demoTasks(carId: saved.id))
        }
        scheduleNotifications()
    }

    func updateCar(_ car: Car) {
        carStore.update(car)
    }

    func deleteCar(_ car: Car) {
        taskStore.deleteTasks(for: car.id)
        carStore.delete(car)
        if activeCarId == car.id {
            activeCarId = carStore.cars.first?.id
        }
    }

    func selectCar(_ car: Car) {
        activeCarId = car.id
        prefs.saveActiveCarId(car.id)
    }

    // MARK: - Task actions

    func markDone(_ taskId: Int64) {
        taskStore.markDone(taskId)
        scheduleNotifications()
    }

    func snoozeTask(_ taskId: Int64) {
        taskStore.snooze(taskId)
        scheduleNotifications()
    }

    func updateTask(_ task: ComplianceTask) {
        taskStore.update(task)
        scheduleNotifications()
    }

    // MARK: - AI refresh

    func refreshTasks(for car: Car) async {
        guard let config = prefs.apiKeyConfig else { return }
        isRefreshing = true
        await generateTasks(for: car, config: config)
        isRefreshing = false
        scheduleNotifications()
    }

    private func generateTasks(for car: Car, config: ApiKeyConfig) async {
        let result = await AiApiService.shared.generateComplianceTasks(car: car, config: config)
        switch result {
        case .success(let aiTasks):
            taskStore.deleteTasks(for: car.id)
            let mapped = aiTasks.map { $0.toComplianceTask(carId: car.id) }
            taskStore.insertAll(mapped)
            lastApiError = nil
            prefs.clearApiError()
        case .failure(let msg):
            lastApiError = msg
            prefs.lastApiError = msg
        }
    }

    private func scheduleNotifications() {
        NotificationScheduler.shared.scheduleAll(
            tasks: taskStore.allActive(),
            prefs: prefs.notificationPrefs
        )
    }

    // MARK: - Demo tasks

    private func demoTasks(carId: Int64) -> [ComplianceTask] {
        let cal = Calendar.current
        return [
            ComplianceTask(
                carId: carId, title: "Technical inspection",
                category: .legal,
                dueDate: cal.date(byAdding: .month, value: 2, to: Date()),
                dueDateWindow: "In ~2 months", status: .upcoming, urgency: .medium,
                why: "Annual technical inspection is required by law for vehicles over 4 years old in most countries."
            ),
            ComplianceTask(
                carId: carId, title: "Liability insurance renewal",
                category: .insurance,
                dueDate: cal.date(byAdding: .month, value: 3, to: Date()),
                dueDateWindow: "In ~3 months", status: .upcoming, urgency: .medium,
                why: "Third-party liability insurance is mandatory in most countries. Driving without it can result in significant fines."
            ),
            ComplianceTask(
                carId: carId, title: "Engine oil & filter change",
                category: .maintenance,
                dueDate: cal.date(byAdding: .day, value: 14, to: Date()),
                dueDateWindow: "In ~2 weeks", status: .upcoming, urgency: .high,
                why: "Typical petrol engine oil change interval: 10,000-15,000 km or 12 months. Overdue oil degrades engine components."
            ),
        ]
    }
}
