import SwiftUI
import SwiftData // Import SwiftData

struct CalendarView: View {
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
                    // Using short symbols for brevity (e.g., S, M, T)
                    // Get the symbols array first
                    let weekdaySymbols: [String] = calendar.veryShortWeekdaySymbols
                    // Iterate over the indices (0 to 6) which are unique
                    ForEach(weekdaySymbols.indices, id: \.self) { index in
                        // Get the symbol using the index
                        let symbol: String = weekdaySymbols[index]
                        Text(symbol)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date: Date = date {
                            // Look up the log for this date in our dictionary
                            let logForDay: DailyLog? = logsForMonthDict[date]
                            
                            // Use DayCellView, passing the date and the found log (or nil)
                            DayCellView(date: date, dailyLog: logForDay)
                                // TODO: Add tap gesture/NavigationLink here later
                        } else {
                            // Empty cell for days outside the current month
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                    }
                }
                .padding()

                Spacer() // Pushes everything to the top
            }
            .navigationTitle("Calendar") // Title for the view
            // .navigationBarTitleDisplayMode(.inline) // Removed for potential macOS compatibility
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
    }

    // Helper function to generate the dates for the grid, including padding
    // for days outside the current month to align weeks correctly.
    private func daysInMonth() -> [Date?] {
        guard let monthInterval: DateInterval = calendar.dateInterval(of: .month, for: displayMonth),
              let monthFirstWeek: DateInterval = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              // Get the last day of the month safely (it's optional)
              let lastDayOfMonth: Date = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              // Now use the unwrapped lastDayOfMonth to get the week interval
              let monthLastWeek: DateInterval = calendar.dateInterval(of: .weekOfMonth, for: lastDayOfMonth)
        else {
            // If any of these calculations fail, return an empty array
            return []
        }

        var days: [Date?] = []
        let startDate: Date = monthFirstWeek.start
        let endDate: Date = monthLastWeek.end

        // Iterate day by day from the start of the first week to the end of the last week.
        var currentDate: Date = startDate
        while currentDate < endDate {
            // If the day falls within the target month, add it.
            if currentDate >= monthInterval.start && currentDate < monthInterval.end {
                days.append(currentDate)
            } else {
                // Otherwise, add nil as a placeholder for empty cells in the grid.
                days.append(nil)
            }

            // Safely move to the next day.
            guard let nextDay: Date = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                // This should theoretically never happen when just adding 1 day,
                // but it's good practice to handle the optional.
                break // Exit loop if we somehow can't calculate the next day
            }
            currentDate = nextDay
        }
        return days
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