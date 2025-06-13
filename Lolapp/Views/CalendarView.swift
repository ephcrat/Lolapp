import SwiftUI
import SwiftData // Import SwiftData

struct CalendarView: View {
    // Environment variable to detect app lifecycle changes
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    // State variable to keep track of the month being displayed.
    // It defaults to the current month when the view first appears.
    @State private var displayMonth: Date = Date()
    
    // SwiftData Query: Fetches all DailyLog objects, sorted by date.
    // We will filter this array later based on the displayMonth.
    // The `sort:` parameter ensures the data is ordered.
    @Query(sort: \DailyLog.date) private var dailyLogs: [DailyLog]
    
    // Access the system's calendar
    private let calendar: Calendar = Calendar.current
    // Define the grid columns for the days (7 days a week)
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)
    
    // We need a way to tell DayCellView to re-evaluate isToday
    // This is a @State variable that we toggle to force redraws
    // when the app becomes active and the day might have changed.
    @State private var appBecameActiveTrigger: Bool = false
    
    // Computed property to create a lookup dictionary from the logs
    // This dictionary maps a normalized Date (start of day) to its DailyLog.
    // It recalculates whenever dailyLogs or displayMonth changes.
    private var logsForMonthDict: [Date: DailyLog] {
        // Filter logs for the currently displayed month for efficiency
        guard let monthInterval: DateInterval = calendar.dateInterval(of: .month, for: displayMonth) else {
            return [:]
        }
        
        let logsInMonth: [DailyLog] = dailyLogs.filter { log in
            // Ensure log date is within the month interval
            // Note: DailyLog dates are already normalized to start of day in the initializer
            return log.date >= monthInterval.start && log.date < monthInterval.end
        }
        
        // Create the dictionary [Date: DailyLog]
        // Using Dictionary(uniqueKeysWithValues:) is efficient.
        // We assume dates are unique due to the @Attribute(.unique) on DailyLog.date
        return Dictionary(uniqueKeysWithValues: logsInMonth.map { ($0.date, $0) })
    }
    
    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential future navigation
            VStack {
                // Header: Month/Year and Navigation Buttons
                CalendarHeaderView(displayMonth: $displayMonth)
                
                // Day of the Week Labels
                HStack {
                    // Get the symbols array first, and ensure their order matches how we calculate dates
                    let weekdaySymbols: [String] = calendar.veryShortWeekdaySymbols
                    
                    // Check if the calendar's first weekday is different than the default
                    // Most calendars start Sunday (1) but some may be configured to start Monday (2)
                    // The indices are 1-based in Calendar but we need 0-based for our array
                    let firstWeekdayIndex = calendar.firstWeekday - 1
                    
                    // Get the correctly ordered weekday symbols based on the calendar's first weekday setting
                    let orderedSymbols = Array(weekdaySymbols[firstWeekdayIndex..<weekdaySymbols.count] + weekdaySymbols[0..<firstWeekdayIndex])
                    
                    // Use these reordered symbols for display
                    ForEach(orderedSymbols.indices, id: \.self) { index in
                        let symbol: String = orderedSymbols[index]
                        Text(symbol)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(daysInMonth().enumerated()), id: \.offset) { index, date in
                        if let date: Date = date {
                            let logForDay = logsForMonthDict[date]
                            NavigationLink(destination: DayDetailView(selectedDate: date)) {
                                DayCellView(date: date, dailyLog: logForDay, appBecameActiveTrigger: appBecameActiveTrigger)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                    }
                }
                .padding()
                
                Spacer() // Pushes everything to the top
            }
            .navigationTitle("Home") // Title for the view
            // .navigationBarTitleDisplayMode(.inline) // Removed for potential macOS compatibility
            // Add a toolbar for the quick action button
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Place on the right
                    Button {
                        addCoughForToday()
                    } label: {
                        Label("Add Cough for Today", systemImage: "plus.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
            }
        }
        // Re-calculate the dictionary when the displayed month changes
        .onChange(of: displayMonth) { _, _ in
            // The dictionary `logsForMonthDict` is computed on demand,
            // so just accessing it implicitly handles the update when
            // the grid redraws after displayMonth changes.
            // No explicit action needed here, but onChange is useful for debugging
            // or triggering other side effects if necessary.
        }
        // Also re-calculate if the underlying log data changes
        .onChange(of: dailyLogs) { _, _ in
            // Same as above, the computed property handles this automatically.
        }
        // Add onChange for scenePhase
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("App became active. Forcing DayCellView refresh.")
                // Toggle the state variable to force DayCellView to re-evaluate isToday
                appBecameActiveTrigger.toggle()
                
                // Additionally, if the displayMonth is no longer the current actual month,
                // reset displayMonth to the current month to ensure calendar is up-to-date.
                let today = Date()
                if !calendar.isDate(displayMonth, equalTo: today, toGranularity: .month) {
                    print("App active and displayMonth is stale. Resetting to current month.")
                    displayMonth = today
                }
            }
        }
    }
    
    // Helper function to generate the dates for the grid, including padding
    // for days outside the current month to align weeks correctly.
    private func daysInMonth() -> [Date?] {
        guard let monthInterval: DateInterval = calendar.dateInterval(of: .month, for: displayMonth),
              let firstDayOfMonth: Date = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))
        else {
            return []
        }
        
        // Calculate the first visible day in the calendar grid
        // This should be the first day of the week that contains the first day of the month
        var startDateComponents: DateComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: firstDayOfMonth)
        let weekdayOffset: Int = (7 + startDateComponents.weekday! - calendar.firstWeekday) % 7
        startDateComponents.day = startDateComponents.day! - weekdayOffset
        
        guard let startDate: Date = calendar.date(from: startDateComponents) else {
            return []
        }
        
        // Calculate the last visible day in the calendar grid
        // This should be the last day of the week that contains the last day of the month
        guard let lastDayOfMonth: Date = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth),
              var endDateComponents: DateComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: lastDayOfMonth) as DateComponents?
        else {
            return []
        }
        
        let daysToAdd: Int = (7 - ((endDateComponents.weekday! - calendar.firstWeekday + 7) % 7)) % 7
        endDateComponents.day = endDateComponents.day! + daysToAdd
        
        guard let endDate: Date = calendar.date(from: endDateComponents) else {
            return []
        }
        
        // Create the array of dates (and nil placeholders) for the entire visible calendar
        var days: [Date?] = []
        var currentDate: Date = startDate
        
        // Use a consistent way to add days
        while currentDate <= endDate {
            // If the date is within our target month, add the actual date
            if currentDate >= monthInterval.start && currentDate < monthInterval.end {
                days.append(currentDate)
            } else {
                // Otherwise add nil for days outside the current month
                days.append(nil)
            }
            
            // Move to the next day safely
            guard let nextDate: Date = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return days
    }
    
    /// Finds or creates a DailyLog for today and increments its cough count.
    private func addCoughForToday() {
        let today = calendar.startOfDay(for: Date()) // Normalize today's date
        
        // Try to find an existing log for today from our fetched dailyLogs
        // The dailyLogs @Query is already sorted by date, but we need to find the specific one for today.
        // A more robust find would be to iterate, or if we had a dictionary like logsForMonthDict that covered all fetched logs.
        // For simplicity, we'll search the array.
        if let existingLogForToday = dailyLogs.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            existingLogForToday.coughCount += 1
            print("Incremented cough for existing log on \(today). New count: \(existingLogForToday.coughCount)")
        } else {
            // If no log exists, create a new one with coughCount = 1 and insert it.
            let newLog = DailyLog(date: today, coughCount: 1)
            modelContext.insert(newLog)
            print("Created new log for today (\(today)) with 1 cough.")
        }
        
    }
}

// Separate View for the Calendar Header (Month/Year + Navigation)
struct CalendarHeaderView: View {
    @Binding var displayMonth: Date // Use @Binding to modify the state in the parent view
    private let calendar: Calendar = Calendar.current
    
    var body: some View {
        HStack {
            // Previous Month Button
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .padding()
                    .contentShape(Rectangle()) // Increase tappable area
            }
            
            Spacer()
            
            // Month and Year Display
            Text(monthYearString(from: displayMonth))
                .font(.title2.weight(.semibold)) // Slightly larger font
                .padding(.vertical)
            
            Spacer()
            
            // Next Month Button
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .padding()
                    .contentShape(Rectangle()) // Increase tappable area
            }
        }
        .padding(.horizontal)
    }
    
    // Function to change the displayed month
    private func changeMonth(by months: Int) {
        // Use the calendar to safely add/subtract months
        if let newMonth: Date = calendar.date(byAdding: .month, value: months, to: displayMonth) {
            displayMonth = newMonth
        }
    }
    
    // Function to format the date into "Month Year"
    private func monthYearString(from date: Date) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // e.g., "July 2024"
        return formatter.string(from: date)
    }
}

// Preview Provider for Xcode Canvas
#Preview {
    // To make the preview work with @Query, we need to provide a ModelContainer.
    // Using an in-memory container is best practice for previews.
    do {
        let config: ModelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container: ModelContainer = try ModelContainer(for: DailyLog.self, configurations: config)
        
        // Add multiple sample logs for better preview testing
        let todayLog = DailyLog(date: Date(), coughCount: 1, isPrednisoneScheduled: true)
        let yesterdayLog = DailyLog(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, coughCount: 4, isPrednisoneScheduled: false)
        let twoDaysAgoLog = DailyLog(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, coughCount: 0, isPrednisoneScheduled: true)
        let fiveDaysAgoLog = DailyLog(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, coughCount: 7, isPrednisoneScheduled: false)
        
        container.mainContext.insert(todayLog)
        container.mainContext.insert(yesterdayLog)
        container.mainContext.insert(twoDaysAgoLog)
        container.mainContext.insert(fiveDaysAgoLog)
        
        return CalendarView()
            .modelContainer(container) // Provide the container to the view
    } catch {
        // Handle error creating the container (e.g., display an error message)
        fatalError("Failed to create model container for preview: \(error.localizedDescription)")
    }
} 
