import SwiftUI
import SwiftData

struct DayCellView: View {
    let date: Date
    let dailyLog: DailyLog?
    let appBecameActiveTrigger: Bool // Trigger to force a re-evaluation of isToday
    
    private let calendar: Calendar = Calendar.current
    private var isToday: Bool {
        let today: Date = calendar.startOfDay(for: Date())
        let cellDate: Date = calendar.startOfDay(for: date)
        return calendar.isDate(cellDate, inSameDayAs: today)
    }
    
    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.headline)
                .padding(8)
                .frame(maxWidth: .infinity) // Expand horizontally
                .background(backgroundForDay())
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2) // Blue border for today
                )
                .overlay(alignment: .bottomTrailing) {
                    if showPrednisoneDot() {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .padding(4)
                    }
                }
        }
        .frame(minHeight: 50)
    }
    
    // --- Helper Functions for Visualization --- 
    
    
    private func backgroundForDay() -> Color {
        guard let log: DailyLog = dailyLog else {
            return Color.gray.opacity(0.1) // Default background for days with no log
        }
        
        let opacity: Double = switch log.coughCount {
        case 0: 0.1
        case 1: 0.35
        case 2: 0.55
        case 3: 0.75
        case 4...6: 0.9
        default: 1.0
        }
        
        return Color.purple.opacity(opacity)
    }
    
    private func showPrednisoneDot() -> Bool {
        return dailyLog?.isPrednisoneScheduled ?? false
    }
}

// --- Preview --- 

#Preview("No Log") {
    DayCellView(date: Date(), dailyLog: nil, appBecameActiveTrigger: false)
        .padding()
}

#Preview("Today With Log") {
    let log: DailyLog = DailyLog(date: Date(), coughCount: 4, isPrednisoneScheduled: true)
    return DayCellView(date: Date(), dailyLog: log, appBecameActiveTrigger: false)
        .padding()
}

#Preview("Other Day No Dot") {
    let date: Date = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
    let log: DailyLog = DailyLog(date: date, coughCount: 1)
    return DayCellView(date: date, dailyLog: log, appBecameActiveTrigger: false)
        .padding()
} 
