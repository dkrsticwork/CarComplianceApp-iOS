import SwiftUI

// MARK: - Root tab container

struct MainView: View {
    @EnvironmentObject var appState: AppState
    var onAddCar: () -> Void
    var onEditCar: (Car) -> Void
    var onGoToApiKey: () -> Void

    var body: some View {
        TabView {
            GarageTab(onAddCar: onAddCar, onEditCar: onEditCar)
                .tabItem { Label("Garage", systemImage: "car.2.fill") }
            TasksTab(onGoToApiKey: onGoToApiKey)
                .tabItem { Label("Tasks", systemImage: "checklist") }
            TimelineTab()
                .tabItem { Label("Timeline", systemImage: "calendar") }
            SettingsTab(onGoToApiKey: onGoToApiKey)
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

// MARK: - Garage

struct GarageTab: View {
    @EnvironmentObject var appState: AppState
    var onAddCar: () -> Void
    var onEditCar: (Car) -> Void

    var body: some View {
        NavigationView {
            Group {
                if appState.cars.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No cars yet")
                            .font(.title2).bold()
                        Text("Add your first car to get started.")
                            .foregroundColor(.secondary)
                        Button("Add Car", action: onAddCar)
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(appState.cars) { car in
                            CarRow(
                                car: car,
                                isActive: appState.activeCarId == car.id,
                                onSelect: { appState.selectCar(car) },
                                onEdit: { onEditCar(car) },
                                onDelete: { appState.deleteCar(car) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onAddCar) { Image(systemName: "plus") }
                }
            }
        }
    }
}

struct CarRow: View {
    let car: Car
    let isActive: Bool
    var onSelect: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(car.nickname).font(.headline)
                Text("\(car.year) · \(car.fuelType.displayName) · \(car.countryCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Edit", action: onEdit).tint(.blue)
        }
    }
}

// MARK: - Tasks

struct TasksTab: View {
    @EnvironmentObject var appState: AppState
    var onGoToApiKey: () -> Void

    var body: some View {
        NavigationView {
            Group {
                if appState.activeCar == nil {
                    Text("Add a car first")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    taskList
                }
            }
            .navigationTitle(appState.activeCar?.nickname ?? "Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let car = appState.activeCar {
                        Button {
                            Task { await appState.refreshTasks(for: car) }
                        } label: {
                            if appState.isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(appState.isRefreshing)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var taskList: some View {
        List {
            if let err = appState.lastApiError {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Error").font(.headline)
                            Text(err).font(.caption).foregroundColor(.secondary)
                            Button("Set API Key", action: onGoToApiKey)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if appState.tasks.isEmpty {
                Text("No active tasks")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(appState.tasks) { task in
                    TaskRow(
                        task: task,
                        onDone: { appState.markDone(task.id) },
                        onSnooze: { appState.snoozeTask(task.id) }
                    )
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: ComplianceTask
    var onDone: () -> Void
    var onSnooze: () -> Void

    var urgencyColor: Color {
        switch task.urgency {
        case .critical: return .red
        case .high:     return .orange
        case .medium:   return .yellow
        case .low:      return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(urgencyColor)
                    .frame(width: 10, height: 10)
                Text(task.title).font(.headline)
                Spacer()
                Text(task.category.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
            }
            if !task.dueDateWindow.isEmpty {
                Text(task.dueDateWindow)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(task.why)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button("Done", action: onDone).tint(.green)
            Button("Snooze 7d", action: onSnooze).tint(.blue)
        }
    }
}

// MARK: - Timeline

struct TimelineTab: View {
    @EnvironmentObject var appState: AppState

    private var sorted: [ComplianceTask] {
        appState.tasks
            .filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationView {
            List(sorted) { task in
                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.25))
                            .frame(width: 2)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.subheadline)
                            .bold()
                        if let due = task.dueDate {
                            Text(dateFormatter.string(from: due))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(task.dueDateWindow)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .frame(minHeight: 52)
            }
            .navigationTitle("Timeline")
        }
    }
}

// MARK: - Settings

struct SettingsTab: View {
    @EnvironmentObject var appState: AppState
    var onGoToApiKey: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Key")) {
                    if let config = appState.prefs.apiKeyConfig {
                        HStack {
                            Text("Provider")
                            Spacer()
                            Text(config.provider.displayName)
                                .foregroundColor(.secondary)
                        }
                        Button("Change API Key", action: onGoToApiKey)
                        Button("Remove API Key", role: .destructive) {
                            appState.prefs.apiKeyConfig = nil
                        }
                    } else {
                        Button("Set API Key", action: onGoToApiKey)
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("30 days before deadline", isOn: Binding(
                        get: { appState.prefs.notificationPrefs.thirtyDays },
                        set: { v in appState.prefs.notificationPrefs.thirtyDays = v }
                    ))
                    Toggle("7 days before deadline", isOn: Binding(
                        get: { appState.prefs.notificationPrefs.sevenDays },
                        set: { v in appState.prefs.notificationPrefs.sevenDays = v }
                    ))
                    Toggle("1 day before deadline", isOn: Binding(
                        get: { appState.prefs.notificationPrefs.oneDay },
                        set: { v in appState.prefs.notificationPrefs.oneDay = v }
                    ))
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
