import SwiftUI
import SwiftData

enum FocusedField {
    case asthmaPuffs
    case prednisoneDosage
    case notes
}

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
    @FocusState private var focusedField: FocusedField?
    
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
        List {
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
                
                coughTrackingSection(bindableLog)
                prednisoneSection(bindableLog)
                asthmaMedSection(bindableLog)
                nutritionSection(bindableLog)
                notesSection(bindableLog)
                
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
                    focusedField = nil
                }
            }
        }
        .onAppear(perform: loadExistingLog)
        .sheet(isPresented: $showingSoftFoodLogSheet) {
            if let currentActiveLog: DailyLog = activeLog {
                SoftFoodLogSheetView(log: currentActiveLog).tint(DEFAULT_ACCENT_COLOR)
            } else {
                Text("Error: No active log available for the sheet.")
            }
        }
    }
    
    // --- Section Views ---
    
    private func coughTrackingSection(_ log: DailyLog) -> some View {
        CoughTrackingSectionView(log: log)
            .onChange(of: log.coughCount) { _, _ in handleLogChange(log) }
    }
    
    private func prednisoneSection(_ log: DailyLog) -> some View {
        let prednisoneBinding: Binding<Bool> = Binding<Bool>(
            get: { self.expandedSection == .prednisone },
            set: { newValue in self.expandedSection = newValue ? .prednisone : .none }
        )
        return  PrednisoneSectionView(log: log, numberFormatter: numberFormatter, isExpanded: prednisoneBinding, focusedField: $focusedField)
            .onChange(of: log.isPrednisoneScheduled) { _, _ in handleLogChange(log) }
            .onChange(of: log.prednisoneDosageDrops) { _, _ in handleLogChange(log) }
            .onChange(of: log.prednisoneFrequency) { _, _ in handleLogChange(log) }
            .onChange(of: log.didAdministerPrednisoneDose1) { _, _ in handleLogChange(log) }
            .onChange(of: log.didAdministerPrednisoneDose2) { _, _ in handleLogChange(log) }
    }
    
    private func asthmaMedSection(_ log: DailyLog) -> some View {
        let asthmaBinding: Binding<Bool> = Binding<Bool>(
            get: { self.expandedSection == .asthma },
            set: { newValue in self.expandedSection = newValue ? .asthma : .none }
        )
        return AsthmaMedSectionView(log: log, numberFormatter: numberFormatter, isExpanded: asthmaBinding, focusedField: $focusedField)
            .onChange(of: log.asthmaMedDosagePuffs) { _, _ in handleLogChange(log) }
            .onChange(of: log.asthmaMedFrequency) { _, _ in handleLogChange(log) }
            .onChange(of: log.didAdministerAsthmaMedDose1) { _, _ in handleLogChange(log) }
            .onChange(of: log.didAdministerAsthmaMedDose2) { _, _ in handleLogChange(log) }
    }
    
    private func nutritionSection(_ log: DailyLog) -> some View {
        Section(header: Text("Nutrition").font(.headline)) {
            Button(action: {
                self.showingSoftFoodLogSheet = true
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
                .foregroundColor(.primary)
            }
            .onChange(of: log.foodEntries) { _, _ in handleLogChange(log) }
            .onChange(of: log.softFoodTargetGrams) { _, _ in handleLogChange(log) }
        }
        
    }
    
    private func notesSection(_ log: DailyLog) -> some View {
        Section(header: Text("Observations").font(.headline)) {
            NotesSectionView(log: log, focusedField: $focusedField)
                .onChange(of: log.notes) { _, _ in
                    handleLogChange(log)
                }
        }
    }
    
    // --- Helper Functions ---
    
    /// Combined handler for ensuring log exists and checking for deletion
    private func handleLogChange(_ log: DailyLog) {
        ensureLogExists(log)
        checkIfLogShouldBeDeleted(log)
    }
    
    /// Loads an existing log if one exists, but doesn't create a new one
    private func loadExistingLog() {
        
        editingLog = dailyLogs.first
        
        // If no existing log was found, create a temporary one for display
        if editingLog == nil && temporaryLog == nil {
            temporaryLog = DailyLog(date: selectedDate)
        }
    }
    
    /// Ensures the log exists in the database if it's just a temporary log
    private func ensureLogExists(_ log: DailyLog) {
        if editingLog == nil && log == temporaryLog {
            // Insert the temporary log into the context to make it persistent
            modelContext.insert(log)
            editingLog = log
            temporaryLog = nil
        }
    }
    
    /// Checks if the log should be deleted because all values are at defaults
    private func checkIfLogShouldBeDeleted(_ log: DailyLog) {
        guard log == editingLog else { return }
        
        if log.isAtDefaultState {
            modelContext.delete(log)
            editingLog = nil
            temporaryLog = DailyLog(date: selectedDate)
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
            
            let previewDate: Date = Calendar.current.startOfDay(for: Date())
            
            return DayDetailView(selectedDate: previewDate)
                .modelContainer(container)
        } catch {
            fatalError("Failed to create model container for preview: \(error.localizedDescription)")
        }
    }
}
