import SwiftUI

struct ApiKeyView: View {
    @EnvironmentObject var appState: AppState
    var onContinue: () -> Void
    var onBack: () -> Void

    @State private var rawKey = ""
    @State private var detectedProvider: AiProvider?
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Provider API Key")) {
                    SecureField("Paste your API key here", text: $rawKey)
                        .onChange(of: rawKey) { _, key in
                            detectedProvider = key.isEmpty ? nil : Preferences.shared.detectProvider(key)
                        }

                    if let provider = detectedProvider {
                        Label(provider.displayName, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Section(footer: Text("Supported providers: OpenAI (sk-...), Anthropic (sk-ant-...), Google Gemini (AIza...), Mistral AI, Cohere.\n\nYour key is stored only on this device.")) {
                    EmptyView()
                }

                Section {
                    Button(action: save) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                Text("Saving…").padding(.leading, 8)
                            }
                        } else {
                            Text("Save & Continue")
                        }
                    }
                    .disabled(rawKey.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .navigationTitle("API Key")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
            .onAppear {
                if let config = appState.prefs.apiKeyConfig {
                    rawKey = config.rawKey
                    detectedProvider = config.provider
                }
            }
        }
    }

    private func save() {
        let key = rawKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        isSaving = true
        let provider = detectedProvider ?? Preferences.shared.detectProvider(key)
        appState.prefs.apiKeyConfig = ApiKeyConfig(rawKey: key, provider: provider)
        isSaving = false
        onContinue()
    }
}
