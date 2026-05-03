import SwiftUI

struct AddCarView: View {
    @EnvironmentObject var appState: AppState
    var editCar: Car? = nil
    var onSaved: () -> Void
    var onBack: () -> Void

    @State private var countryCode = "RS"
    @State private var countryDisplay = "Serbia 🇷🇸"
    @State private var makeQuery = ""
    @State private var selectedMake = ""
    @State private var selectedModel = ""
    @State private var selectedYear: Int? = nil
    @State private var selectedFuel: FuelType = .petrol
    @State private var lastServiceMonth = ""
    @State private var insuranceExpiry = ""
    @State private var registrationExpiry = ""
    @State private var odometerKm = ""
    @State private var isLoading = false
    @State private var showCountryPicker = false
    @State private var showMakeSuggestions = false

    private var filteredMakes: [String] {
        if makeQuery.isEmpty { return Array(CAR_MAKES.prefix(8)) }
        return CAR_MAKES.filter { $0.localizedCaseInsensitiveContains(makeQuery) }.prefix(8).map { $0 }
    }

    private var availableModels: [String] {
        CAR_MODELS[selectedMake] ?? DEFAULT_MODELS
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        NavigationView {
            Form {
                // Country
                Section(header: Text("Country")) {
                    Button(action: { showCountryPicker = true }) {
                        HStack {
                            Text(countryDisplay)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Make / Model / Year / Fuel
                Section(header: Text("Vehicle")) {
                    TextField("Make (e.g. Volkswagen)", text: $makeQuery)
                        .onChange(of: makeQuery) { _, value in
                            showMakeSuggestions = !value.isEmpty
                            if value != selectedMake {
                                selectedMake = ""
                                selectedModel = ""
                            }
                        }

                    if showMakeSuggestions && !filteredMakes.isEmpty {
                        ForEach(filteredMakes, id: \.self) { make in
                            Button(make) {
                                selectedMake = make
                                makeQuery = make
                                selectedModel = ""
                                showMakeSuggestions = false
                            }
                            .foregroundColor(.accentColor)
                        }
                    }

                    if !selectedMake.isEmpty {
                        Picker("Model", selection: $selectedModel) {
                            Text("Select model").tag("")
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    }

                    Picker("Year", selection: $selectedYear) {
                        Text("Select year").tag(Optional<Int>.none)
                        ForEach((1980...currentYear).reversed(), id: \.self) { year in
                            Text(String(year)).tag(Optional(year))
                        }
                    }

                    Picker("Fuel type", selection: $selectedFuel) {
                        ForEach(FuelType.allCases, id: \.self) { fuel in
                            Text(fuel.displayName).tag(fuel)
                        }
                    }
                }

                // Dates
                Section(
                    header: Text("Dates"),
                    footer: Text("Format: yyyy-MM (e.g. 2025-06)")
                ) {
                    TextField("Last service month", text: $lastServiceMonth)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Insurance expiry month", text: $insuranceExpiry)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Registration expiry month", text: $registrationExpiry)
                        .keyboardType(.numbersAndPunctuation)
                }

                // Odometer
                Section(header: Text("Odometer")) {
                    TextField("Kilometres (optional)", text: $odometerKm)
                        .keyboardType(.numberPad)
                }

                // Save
                Section {
                    Button(action: save) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Generating tasks…").padding(.leading, 8)
                            }
                        } else {
                            Text(editCar == nil ? "Add Car & Generate Tasks" : "Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedMake.isEmpty || selectedYear == nil || isLoading)
                }
            }
            .navigationTitle(editCar == nil ? "Add Car" : "Edit Car")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back", action: onBack)
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(selectedCode: $countryCode, selectedDisplay: $countryDisplay)
            }
            .onAppear(perform: prefill)
        }
    }

    // MARK: - Prefill for edit mode

    private func prefill() {
        guard let car = editCar else { return }
        countryCode = car.countryCode
        countryDisplay = COUNTRIES.first { $0.code == car.countryCode }?.display ?? car.countryCode
        selectedMake = car.make
        makeQuery = car.make
        selectedModel = car.model
        selectedYear = car.year
        selectedFuel = car.fuelType
        odometerKm = car.odometerKm.map { String($0) } ?? ""
        let mf = DateFormatter()
        mf.dateFormat = "yyyy-MM"
        lastServiceMonth = car.lastServiceDate.map { mf.string(from: $0) } ?? ""
        insuranceExpiry = car.insuranceExpiry.map { mf.string(from: $0) } ?? ""
        registrationExpiry = car.registrationExpiry.map { mf.string(from: $0) } ?? ""
    }

    // MARK: - Save

    private func save() {
        guard !selectedMake.isEmpty, let year = selectedYear else { return }
        isLoading = true

        let mf = DateFormatter()
        mf.dateFormat = "yyyy-MM-dd"

        func parseMonth(_ s: String) -> Date? {
            guard !s.isEmpty else { return nil }
            return mf.date(from: "\(s)-01")
        }

        var car = Car(
            id: editCar?.id ?? 0,
            nickname: "\(selectedMake) \(selectedModel)".trimmingCharacters(in: .whitespaces),
            make: selectedMake,
            model: selectedModel.isEmpty ? selectedMake : selectedModel,
            year: year,
            fuelType: selectedFuel,
            countryCode: countryCode,
            lastServiceDate: parseMonth(lastServiceMonth),
            insuranceExpiry: parseMonth(insuranceExpiry),
            registrationExpiry: parseMonth(registrationExpiry),
            odometerKm: Int(odometerKm)
        )

        Task {
            if editCar != nil {
                car.id = editCar!.id
                await MainActor.run { appState.updateCar(car) }
            } else {
                await appState.saveCar(car, apiConfig: appState.prefs.apiKeyConfig)
            }
            await MainActor.run {
                isLoading = false
                onSaved()
            }
        }
    }
}

// MARK: - Country Picker

struct CountryPickerView: View {
    @Binding var selectedCode: String
    @Binding var selectedDisplay: String
    @Environment(\.dismiss) var dismiss
    @State private var query = ""

    private var filtered: [(code: String, display: String)] {
        query.isEmpty ? COUNTRIES : COUNTRIES.filter { $0.display.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationView {
            List(filtered, id: \.code) { country in
                Button {
                    selectedCode = country.code
                    selectedDisplay = country.display
                    dismiss()
                } label: {
                    HStack {
                        Text(country.display)
                        Spacer()
                        if selectedCode == country.code {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .searchable(text: $query, prompt: "Search country")
            .navigationTitle("Country")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
