import SwiftUI
import SwiftData

struct CoughTrackingSectionView: View {
    @Bindable var log: DailyLog
    
    var body: some View {
        Section("Cough Tracking") {
            HStack {
                Text("Coughs Today:")
                Spacer()
                // Stepper allows easy +/- increments
                // Directly binds to the coughCount property of our log
                Stepper("\(log.coughCount)", value: $log.coughCount, in: 0...100) // Range 0-100
            }
        }
    }
}

// --- Preview --- 
#Preview {
    struct PreviewWrapper: View {
        @State private var sampleLog: DailyLog = DailyLog(date: Date(), coughCount: 3)
        
        var body: some View {
            List { // Using List for preview to see Section styling
                 CoughTrackingSectionView(log: sampleLog)
            }
        }
    }
    return PreviewWrapper()
} 