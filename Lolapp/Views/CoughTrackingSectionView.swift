import SwiftUI
import SwiftData

struct CoughTrackingSectionView: View {
    @Bindable var log: DailyLog
    
    var body: some View {
        HStack {
            Label("Coughs", systemImage: "facemask.fill")
            Spacer()
            Button {
                if log.coughCount > 0 {
                    log.coughCount -= 1
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)

            Text("\(log.coughCount)")
                .font(.headline)
                .frame(minWidth: 30, alignment: .center)

            Button {
                if log.coughCount < 100 {
                    log.coughCount += 1
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
    }
}

// --- Preview --- 
#Preview {
    struct PreviewWrapper: View {
        @State private var sampleLog: DailyLog = DailyLog(date: Date(), coughCount: 3)
        
        var body: some View {
            List {
                 CoughTrackingSectionView(log: sampleLog)
            }
        }
    }
    return PreviewWrapper()
} 