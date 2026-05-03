import Foundation
import Combine

// MARK: - CarStore

final class CarStore: ObservableObject {
    @Published private(set) var cars: [Car] = []
    private let url: URL

    init() {
        url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cars.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Car].self, from: data) else { return }
        cars = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(cars) else { return }
        try? data.write(to: url, options: .atomic)
    }

    @discardableResult
    func insert(_ car: Car) -> Car {
        var c = car
        c.id = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 0..<1000)
        cars.append(c)
        save()
        return c
    }

    func update(_ car: Car) {
        if let i = cars.firstIndex(where: { $0.id == car.id }) {
            cars[i] = car
            save()
        }
    }

    func delete(_ car: Car) {
        cars.removeAll { $0.id == car.id }
        save()
    }
}

// MARK: - TaskStore

final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [ComplianceTask] = []
    private let url: URL

    init() {
        url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tasks.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ComplianceTask].self, from: data) else { return }
        tasks = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func tasks(for carId: Int64) -> [ComplianceTask] {
        tasks.filter { $0.carId == carId && $0.status != .done && $0.status != .snoozed }
    }

    func allActive() -> [ComplianceTask] {
        tasks.filter { $0.status != .done && $0.status != .snoozed }
    }

    func insert(_ task: ComplianceTask) {
        var t = task
        t.id = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 0..<1000)
        tasks.append(t)
        save()
    }

    func insertAll(_ newTasks: [ComplianceTask]) {
        let stamped = newTasks.map { t -> ComplianceTask in
            var t2 = t
            t2.id = Int64(Date().timeIntervalSince1970 * 1000) + Int64.random(in: 0..<1000)
            return t2
        }
        tasks.append(contentsOf: stamped)
        save()
    }

    func update(_ task: ComplianceTask) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i] = task
            save()
        }
    }

    func markDone(_ id: Int64) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].status = .done
            tasks[i].completedAt = Date()
            save()
        }
    }

    func snooze(_ id: Int64, days: Int = 7) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].status = .snoozed
            tasks[i].snoozedUntil = Calendar.current.date(byAdding: .day, value: days, to: Date())
            save()
        }
    }

    func deleteTasks(for carId: Int64) {
        tasks.removeAll { $0.carId == carId }
        save()
    }
}
