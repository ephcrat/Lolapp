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
    // Environment access for saving changes
    @Environment(\.modelContext) private var modelContext: ModelContext
    // State variable to hold the log being edited. Initialized in onAppear.
    @State private var editingLog: DailyLog? = nil

    // The specific date this view is for.
    let selectedDate: Date

    // Query to find the specific DailyLog for the selectedDate.
    // Note: The query updates automatically if the log changes elsewhere.
    @Query private var dailyLogs: [DailyLog]

    // Initializer to filter the query based on the selected date.
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        // Normalize the date to the start of the day for accurate fetching
        let calendar: Calendar = Calendar.current
        let startOfDay: Date = calendar.startOfDay(for: selectedDate)
        
        // Create the predicate to filter logs for the specific day
        let predicate: Predicate<DailyLog> = #Predicate<DailyLog> { log in
            log.date == startOfDay
        }
        
        // Initialize the @Query with the specific predicate
        // We sort by date too, though there should only be one result.
        _dailyLogs = Query(filter: predicate, sort: \DailyLog.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section 1: Display Selected Date
            Text(selectedDate, style: .date)
                .font(.largeTitle)
                .bold()
                .padding(.bottom)

            // Check if the editingLog has been loaded
            if let log: DailyLog = editingLog {
                // Use @Bindable to allow direct modification of the log's properties
                @Bindable var bindableLog: DailyLog = log
                
                // Wrap sections in a ScrollView in case content gets long
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        CoughTrackingSectionView(log: bindableLog)
                        
                        PrednisoneSectionView(log: bindableLog, numberFormatter: numberFormatter)
                        
                        AsthmaMedSectionView(log: bindableLog, numberFormatter: numberFormatter)

                        SoftFoodSectionView(log: bindableLog)

                        NotesSectionView(log: bindableLog)

                        
                        Spacer() // Push content to top within ScrollView
                    }
                }
            } else {
                // Show a loading state or placeholder while log is prepared
                ProgressView()
                Spacer()
            }
        }
        .padding() // Add padding around the VStack content
        .navigationTitle("Daily Log") // Set title for the navigation bar
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadOrCreateLog) // Load or create the log when view appears
    }

    /// Loads the existing log for the selectedDate or creates and inserts a new one.
    private func loadOrCreateLog() {
        // Check if we already loaded it (e.g., view reappeared)
        guard editingLog == nil else { return }
        
        if let existingLog: DailyLog = dailyLogs.first {
            // If a log for this date exists, use it for editing.
            editingLog = existingLog
            print("Loaded existing log for \(selectedDate)")
        } else {
            // If no log exists, create a new one for the selected date.
            let newLog: DailyLog = DailyLog(date: selectedDate)
            // IMPORTANT: Insert the new log into the context immediately.
            // This makes it managed by SwiftData so changes will be saved.
            modelContext.insert(newLog)
             // Assign the newly created log to our state variable for editing.
            editingLog = newLog
            print("Created and inserted new log for \(selectedDate)")
             // Note: SwiftData might automatically save, but explicit save can be added if needed.
             // try? modelContext.save()
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