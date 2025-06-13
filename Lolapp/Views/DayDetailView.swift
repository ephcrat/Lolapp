import SwiftUI
import SwiftData


let numberFormatter: NumberFormatter = {
    let formatter: NumberFormatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimum = 0
    formatter.allowsFloats = false
    return formatter
}()

// Enum to identify expandable sections
enum MedicationSectionIdentifier {
    case prednisone, asthma, none
}

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var editingLog: DailyLog? = nil
    
    // New state for when we're editing but don't have a persistent log yet
    @State private var temporaryLog: DailyLog? = nil
    @State private var showingSoftFoodLogSheet: Bool = false
    @State private var expandedSection: MedicationSectionIdentifier = .none // Tracks expanded section
    
    // Computed property to get the log we're currently working with
    private var activeLog: DailyLog? {
        return editingLog ?? temporaryLog
    }
    
    let selectedDate: Date
    @Query private var dailyLogs: [DailyLog]

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        let calendar: Calendar = Calendar.current
        let startOfDay: Date = calendar.startOfDay(for: selectedDate)
        let predicate: Predicate<DailyLog> = #Predicate<DailyLog> { log in
            log.date == startOfDay
        }
        _dailyLogs = Query(filter: predicate, sort: \DailyLog.date)
    }

    var body: some View {
        // Use List for the settings-like appearance
        List {
            // Section 1: Display Selected Date
            Section {
                Text(selectedDate, style: .date)
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.clear)

            // Check if we have an active log to display
            if let log: DailyLog = activeLog {
                @Bindable var bindableLog: DailyLog = log
                
                // Cough Tracking - now a direct list item
                CoughTrackingSectionView(log: bindableLog)
                    .onChange(of: bindableLog.coughCount) { _, _ in handleLogChange(log) }

                // Prednisone Section with binding for accordion
                let prednisoneBinding = Binding<Bool>(
                    get: { self.expandedSection == .prednisone },
                    set: { newValue in self.expandedSection = newValue ? .prednisone : .none }
                )
                PrednisoneSectionView(log: bindableLog, numberFormatter: numberFormatter, isExpanded: prednisoneBinding)
                    .onChange(of: bindableLog.isPrednisoneScheduled) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.prednisoneDosageDrops) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.prednisoneFrequency) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.didAdministerPrednisoneDose1) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.didAdministerPrednisoneDose2) { _, _ in handleLogChange(log) }

                // AsthmaMed Section with binding for accordion
                let asthmaBinding = Binding<Bool>(
                    get: { self.expandedSection == .asthma },
                    set: { newValue in self.expandedSection = newValue ? .asthma : .none }
                )
                AsthmaMedSectionView(log: bindableLog, numberFormatter: numberFormatter, isExpanded: asthmaBinding)
                    .onChange(of: bindableLog.asthmaMedDosagePuffs) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.asthmaMedFrequency) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.didAdministerAsthmaMedDose1) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.didAdministerAsthmaMedDose2) { _, _ in handleLogChange(log) }
                
                // Soft Food Intake - styled as a navigation link row
                Section(header: Text("Nutrition").font(.headline)) {
                    Button(action: {
                        ensureLogExists(activeLog ?? DailyLog(date: selectedDate))
                        if activeLog != nil {
                           showingSoftFoodLogSheet = true
                        }
                    }) {
                        HStack {
                             Label(title: {
                                Text("Soft Food Intake")
                            }, icon: {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.accentColor)
                            })
                            Spacer()
                            Text("\(log.softFoodGivenGrams)g / \(log.softFoodTargetGrams)g")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right") // Mimic navigation link
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color(.systemGray4))
                        }
                        .foregroundColor(.primary) // Ensure text is standard color
                    }
                    .onChange(of: bindableLog.foodEntries) { _, _ in handleLogChange(log) }
                    .onChange(of: bindableLog.softFoodTargetGrams) { _, _ in handleLogChange(log) }
                }

                // Notes Section - TextEditor directly in a list section
                Section(header: Text("Observations").font(.headline)) {
                    NotesSectionView(log: bindableLog)
                        .onChange(of: bindableLog.notes) { _, newValue in
                            ensureLogExists(log)
                            if newValue == nil || newValue?.isEmpty == true {
                                checkIfLogShouldBeDeleted(log)
                            }
                        }
                }
                
            } else {
                // If no log exists yet, show a message and create a temporary log
                Section {
                    VStack(spacing: 15) {
                        Text("No data for this day yet.")
                            .font(.headline)
                        Text("Tap below to start tracking or make changes in the sections above.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Start Tracking") {
                            temporaryLog = DailyLog(date: selectedDate)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
        }
        .listStyle(.insetGrouped) // Apply the settings-like list style
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
        .onAppear(perform: loadExistingLog)
        .sheet(isPresented: $showingSoftFoodLogSheet) {
            if let currentActiveLog = activeLog {
                SoftFoodLogSheetView(log: currentActiveLog)
            } else {
                Text("Error: No active log available for the sheet.")
            }
        }
    }

    /// Combined handler for ensuring log exists and checking for deletion
    private func handleLogChange(_ log: DailyLog) {
        ensureLogExists(log)
        checkIfLogShouldBeDeleted(log)
    }

    /// Loads an existing log if one exists, but doesn't create a new one
    private func loadExistingLog() {
        // Set editingLog to the first matching log, or nil if none exists
        editingLog = dailyLogs.first
        
        // If no existing log was found, create a temporary one for display
        if editingLog == nil && temporaryLog == nil {
            temporaryLog = DailyLog(date: selectedDate)
        }
    }
    
    /// Ensures the log exists in the database if it's just a temporary log
    private func ensureLogExists(_ log: DailyLog) {
        // If we're working with a temporary log and it's not yet in the database
        if editingLog == nil && log == temporaryLog {
            // Insert the temporary log into the context to make it persistent
            modelContext.insert(log)
            // Update our state to reference the now-persistent log
            editingLog = log
            // Clear the temporary log reference
            temporaryLog = nil
        }
    }
    
    /// Checks if the log should be deleted because all values are at defaults
    private func checkIfLogShouldBeDeleted(_ log: DailyLog) {
        guard log == editingLog else { return }
        
        // Compare current log values against the global defaults
        let isAtDefaults: Bool = 
            log.coughCount == ModelDefaults.coughCount &&
            (log.notes ?? "").isEmpty &&
            (log.foodEntries ?? []).isEmpty &&
            log.softFoodTargetGrams == ModelDefaults.softFoodTargetGrams &&
            log.isPrednisoneScheduled == ModelDefaults.isPrednisoneScheduled &&
            log.prednisoneDosageDrops == ModelDefaults.prednisoneDosageDrops &&
            log.prednisoneFrequency == ModelDefaults.prednisoneFrequency &&
            log.didAdministerPrednisoneDose1 == ModelDefaults.didAdministerPrednisoneDose1 &&
            (log.prednisoneFrequency != .twiceADay ? log.didAdministerPrednisoneDose2 == nil : log.didAdministerPrednisoneDose2 == ModelDefaults.didAdministerPrednisoneDose2) &&
            log.asthmaMedDosagePuffs == ModelDefaults.asthmaMedDosagePuffs &&
            log.asthmaMedFrequency == ModelDefaults.asthmaMedFrequency &&
            log.didAdministerAsthmaMedDose1 == ModelDefaults.didAdministerAsthmaMedDose1 &&
            (log.asthmaMedFrequency != .twiceADay ? log.didAdministerAsthmaMedDose2 == nil : log.didAdministerAsthmaMedDose2 == ModelDefaults.didAdministerAsthmaMedDose2)
        
        if isAtDefaults {
            modelContext.delete(log)
            editingLog = nil
            temporaryLog = DailyLog(date: selectedDate) // Re-create temporary log using new defaults
            print("Log for \(selectedDate) deleted as all values were at default.")
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// --- Preview --- 

#Preview {
    // Need NavigationView for the title to show correctly in preview
    NavigationView {
        do {
            let config: ModelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container: ModelContainer = try ModelContainer(for: DailyLog.self, configurations: config)
            
            // Sample log for previewing an existing log state
            let previewDate: Date = Calendar.current.startOfDay(for: Date())
            // let sampleLog = DailyLog(date: previewDate, coughCount: 2)
            // container.mainContext.insert(sampleLog)

            // Preview the DayDetailView for a specific date
            // If a sampleLog is inserted above, it will load that one.
            // If not, it will create a new one on appear.
            return DayDetailView(selectedDate: previewDate)
                .modelContainer(container)
        } catch {
            fatalError("Failed to create model container for preview: \(error.localizedDescription)")
        }
    }
} 