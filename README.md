# CarComplianceApp — iOS

Zero external dependencies. Pure SwiftUI + UserDefaults + JSON file persistence.

## Setup in Xcode

1. Open Xcode → File → New → Project
2. Choose **App** template
3. Set:
   - Product Name: `CarComplianceApp`
   - Bundle ID: `com.yourname.CarComplianceApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Save the project **inside** this folder (`CarComplianceApp-iOS/`)
5. In Xcode's Project Navigator, **delete** the auto-generated `ContentView.swift`
6. Right-click the project folder → **Add Files to "CarComplianceApp"**
7. Select all `.swift` files from the `CarComplianceApp/` folder (including subfolders), making sure **"Add to target"** is checked
8. In `Info.plist`, add the key:
   - `NSUserNotificationsUsageDescription` → `"Car compliance deadline reminders"`
9. **Build & Run** (⌘R)

## No packages required

No CocoaPods, no SPM, no Hilt, no Room — nothing to configure.

## File structure

```
CarComplianceApp/
├── CarComplianceApp.swift        # @main entry + RootView navigation
├── Models/
│   ├── Models.swift              # Car, ComplianceTask, enums, AiTask
│   └── CarData.swift             # Makes, models, country list
├── Data/
│   ├── Local/
│   │   ├── Store.swift           # CarStore + TaskStore (JSON file persistence)
│   │   └── Preferences.swift     # UserDefaults wrapper
│   └── Remote/
│       └── AiApiService.swift    # OpenAI / Anthropic / Google / Mistral / Cohere
├── Workers/
│   └── NotificationScheduler.swift  # UNUserNotificationCenter scheduling
└── UI/
    ├── AppState.swift            # @MainActor ObservableObject — single source of truth
    └── Screens/
        ├── Welcome/WelcomeView.swift
        ├── ApiKey/ApiKeyView.swift
        ├── AddCar/AddCarView.swift   # + CountryPickerView
        └── Main/MainView.swift       # Garage / Tasks / Timeline / Settings tabs
```
