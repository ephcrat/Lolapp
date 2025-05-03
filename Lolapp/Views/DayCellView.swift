import SwiftUI
import SwiftData

struct DayCellView: View {
    let date: Date
    let dailyLog: DailyLog? // The log for this specific date, if it exists

    private let calendar: Calendar = Calendar.current
    private var isToday: Bool { calendar.isDateInToday(date) }

    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.headline)
                .padding(8)
                .frame(maxWidth: .infinity) // Expand horizontally
                .background(backgroundForDay())
                .clipShape(Circle()) // Make it circular
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2) // Blue border for today
                )
                .overlay(alignment: .bottomTrailing) {
                     // Add indicator dot if needed
                     if showPrednisoneDot() {
                         Circle()
                             .fill(Color.red) // High-contrast color for the dot
                             .frame(width: 8, height: 8)
                             .padding(4) // Padding from the corner
                     }
                 }
        }
        .frame(minHeight: 50) // Ensure consistent cell height
    }

    // --- Helper Functions for Visualization --- 

    /// Determines the background color/opacity based on cough count.
    private func backgroundForDay() -> Color {
        guard let log: DailyLog = dailyLog else {
            return Color.gray.opacity(0.1) // Default background for days with no log
        }

        // Map cough count to opacity (adjust these values as needed)
        let opacity: Double = switch log.coughCount {
            case 0: 0.1
            case 1...2: 0.3
            case 3...5: 0.5
            default: 0.7 // For 6+ coughs
        }
        
        // You might want a different base color, e.g., blue or purple
        return Color.purple.opacity(opacity)
    }

    /// Determines if the prednisone indicator dot should be shown.
    private func showPrednisoneDot() -> Bool {
        return dailyLog?.isPrednisoneScheduled ?? false
    }
}

// --- Preview --- 

#Preview("No Log") {
    // Preview for a day with no log entry
    DayCellView(date: Date(), dailyLog: nil)
        .padding()
}

#Preview("Today With Log") {
    // Preview for today with a sample log
    let log: DailyLog = DailyLog(date: Date(), coughCount: 4, isPrednisoneScheduled: true)
    return DayCellView(date: Date(), dailyLog: log)
        .padding()
}

#Preview("Other Day No Dot") {
    // Preview for another day with a log but no prednisone
    let date: Date = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
    let log: DailyLog = DailyLog(date: date, coughCount: 1)
    return DayCellView(date: date, dailyLog: log)
        .padding()
} 