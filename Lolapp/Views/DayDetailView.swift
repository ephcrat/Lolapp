import SwiftUI
import SwiftData


let numberFormatter: NumberFormatter = {
    let formatter: NumberFormatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimum = 0
    formatter.allowsFloats = false
    return formatter
}()

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var editingLog: DailyLog? = nil
    
    // New state for when we're editing but don't have a persistent log yet
    @State private var temporaryLog: DailyLog? = nil
    
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
        VStack(alignment: .leading, spacing: 20) {
            // Section 1: Display Selected Date
            Text(selectedDate, style: .date)
                .font(.largeTitle)
                .bold()
                .padding(.bottom)

            // Check if we have an active log to display
            if let log: DailyLog = activeLog {
                @Bindable var bindableLog: DailyLog = log
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        CoughTrackingSectionView(log: bindableLog)
                            .onChange(of: bindableLog.coughCount) { _, newValue in
                                ensureLogExists(log)
                                 // If the value is now default (0) and all other values are default, 
                                // consider deleting the log
                                checkIfLogShouldBeDeleted(log)
                            }
                        
                        PrednisoneSectionView(log: bindableLog, numberFormatter: numberFormatter)
                            .onChange(of: bindableLog.isPrednisoneScheduled) { _, isScheduled in
                                ensureLogExists(log)
                                if !isScheduled {
                                    checkIfLogShouldBeDeleted(log)
                                }
                            }
                            .onChange(of: bindableLog.prednisoneDosageDrops) { _, _ in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log) // Check if dosage change reverts to default
                            }
                            .onChange(of: bindableLog.prednisoneFrequency) { _, _ in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log) // Check if frequency change reverts to default
                            }
                            .onChange(of: bindableLog.didAdministerPrednisoneDose1) { _, _ in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log)
                            }
                            .onChange(of: bindableLog.didAdministerPrednisoneDose2) { _, _ in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log)
                            }
                        
                        AsthmaMedSectionView(log: bindableLog, numberFormatter: numberFormatter)
                            .onChange(of: bindableLog.asthmaMedDosagePuffs) { _, newValue in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log)
                            }
                            .onChange(of: bindableLog.asthmaMedFrequency) { _, newValue in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log)
                            }
                            .onChange(of: bindableLog.didAdministerAsthmaMedDose1) { _, newValue in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log)
                            }
                            .onChange(of: bindableLog.didAdministerAsthmaMedDose2) { _, newValue in
                                ensureLogExists(log)
                                checkIfLogShouldBeDeleted(log)
                            }
                        
                        SoftFoodSectionView(log: bindableLog)
                            .onChange(of: bindableLog.softFoodGivenGrams) { _, newValue in
                                ensureLogExists(log)
                                if newValue == 0 {
                                    checkIfLogShouldBeDeleted(log)
                                }
                            }
                            .onChange(of: bindableLog.softFoodTargetGrams) { _, _ in
                                ensureLogExists(log)
                            }
                        
                        NotesSectionView(log: bindableLog)
                            .onChange(of: bindableLog.notes) { _, newValue in
                                ensureLogExists(log)
                                if newValue == nil || newValue?.isEmpty == true {
                                    checkIfLogShouldBeDeleted(log)
                                }
                            }
                        
                        Spacer()
                    }
                }
            } else {
                // If no log exists yet, show a message and create a temporary log
                VStack(spacing: 20) {
                    Text("No data for this day yet.")
                        .font(.headline)
                    
                    Text("Make changes to create a log.")
                        .foregroundColor(.secondary)
                    
                    Button("Start Tracking") {
                        // Create a temporary log for editing
                        temporaryLog = DailyLog(date: selectedDate)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding()
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExistingLog)
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
        let isAtDefaults = 
            log.coughCount == ModelDefaults.coughCount &&
            log.notes == ModelDefaults.notes && // Handles nil comparison correctly
            log.softFoodGivenGrams == ModelDefaults.softFoodGivenGrams &&
            log.softFoodTargetGrams == ModelDefaults.softFoodTargetGrams &&
            log.isPrednisoneScheduled == ModelDefaults.isPrednisoneScheduled &&
            log.prednisoneDosageDrops == ModelDefaults.prednisoneDosageDrops &&
            log.prednisoneFrequency == ModelDefaults.prednisoneFrequency &&
            log.didAdministerPrednisoneDose1 == ModelDefaults.didAdministerPrednisoneDose1 &&
            // For optional Bools that depend on frequency, their default is effectively nil if not .twiceADay
            // The logic in DailyLog init and section views already handles setting these to nil if frequency isn't .twiceADay.
            // So comparing to ModelDefaults.didAdministerPrednisoneDose2 (which is nil) is correct here if it has been properly nilled out.
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