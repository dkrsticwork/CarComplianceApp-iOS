import SwiftUI

@main
struct CarComplianceApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Root navigation

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var route: Route = .loading
    @State private var carToEdit: Car? = nil

    enum Route {
        case loading, welcome, apiKey, addCar, editCar, main
    }

    var body: some View {
        Group {
            switch route {
            case .loading:
                ProgressView()
                    .onAppear {
                        route = appState.prefs.onboardingDone ? .main : .welcome
                    }

            case .welcome:
                WelcomeView(
                    onGetStarted: { route = .apiKey },
                    onSkipToDemo: { route = .addCar }
                )

            case .apiKey:
                ApiKeyView(
                    onContinue: { route = .addCar },
                    onBack: { route = appState.prefs.onboardingDone ? .main : .welcome }
                )

            case .addCar:
                AddCarView(
                    onSaved: { route = .main },
                    onBack: { route = appState.prefs.onboardingDone ? .main : .welcome }
                )

            case .editCar:
                AddCarView(
                    editCar: carToEdit,
                    onSaved: { route = .main },
                    onBack: { route = .main }
                )

            case .main:
                MainView(
                    onAddCar: { route = .addCar },
                    onEditCar: { car in
                        carToEdit = car
                        route = .editCar
                    },
                    onGoToApiKey: { route = .apiKey }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: route)
    }
}
