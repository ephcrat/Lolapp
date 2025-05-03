import SwiftUI

struct CalendarView: View {
    // State variable to keep track of the month being displayed.
    // It defaults to the current month when the view first appears.
    @State private var displayMonth: Date = Date()

    // Access the system's calendar
    private let calendar: Calendar = Calendar.current
    // Define the grid columns for the days (7 days a week)
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)

    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential future navigation
            VStack {
                // Header: Month/Year and Navigation Buttons
                CalendarHeaderView(displayMonth: $displayMonth)

                // Day of the Week Labels
                HStack {
                    // Using short symbols for brevity (e.g., S, M, T)
                    ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        // Placeholder for each day cell
                        // We'll replace this with a proper DayCellView later
                        if let date = date {
                            Text("\(calendar.component(.day, from: date))")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                // TODO: Add tap gesture later for navigation
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
        if let newMonth = calendar.date(byAdding: .month, value: months, to: displayMonth) {
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
    CalendarView()
} 