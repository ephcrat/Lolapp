import SwiftUI
import SwiftData

struct AsthmaMedSectionView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter 
    
    var body: some View {
        DisclosureGroup("Asthma Medication") {
            AsthmaMedDetailsView(log: log, numberFormatter: numberFormatter)
        }
    }
    // No handleScheduleToggle or .animation based on isAsthmaMedScheduled needed
}

// --- Private Helper View for Asthma Med Details (no changes needed here for isAsthmaMedScheduled) ---
private struct AsthmaMedDetailsView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading) { 
            HStack {
                Text("Dosage (puffs):")
                Spacer()
                TextField("Optional", value: $log.asthmaMedDosagePuffs, formatter: numberFormatter)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            Picker("Frequency:", selection: $log.asthmaMedFrequency) { 
                Text("Not Set").tag(nil as Frequency?)
                ForEach(Frequency.allCases) { freq in
                    Text(freq.displayName).tag(freq as Frequency?)
                }
            }
            .onChange(of: log.asthmaMedFrequency) { _, newFrequency in 
                if newFrequency != .twiceADay {
                    log.didAdministerAsthmaMedDose2 = nil 
                } else if newFrequency == .twiceADay && log.asthmaMedDosagePuffs == nil {
                    // log.asthmaMedDosagePuffs = 1 // Example: Default puffs if not set
                }
            }
            Divider().padding(.vertical, 5)
            Toggle("Administered Dose 1", isOn: $log.didAdministerAsthmaMedDose1)
                .toggleStyle(.switch)
                .padding(.trailing)
            if log.asthmaMedFrequency == .twiceADay { 
                let dose2Binding = Binding<Bool>(
                    get: { log.didAdministerAsthmaMedDose2 ?? false }, 
                    set: { newValue in log.didAdministerAsthmaMedDose2 = newValue } 
                )
                Toggle("Administered Dose 2", isOn: dose2Binding)
                    .toggleStyle(.switch)
                    .padding(.trailing)
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .animation(.default, value: log.asthmaMedFrequency)
    }
}

#Preview { 
    struct PreviewWrapper: View {
        // isAsthmaMedScheduled is no longer part of DailyLog initialization for this context
        @State private var sampleLog = DailyLog(date: Date(), asthmaMedDosagePuffs: 1, asthmaMedFrequency: .onceADay, didAdministerAsthmaMedDose1: true)
        let formatter = numberFormatter 
        var body: some View {
             List { 
                 AsthmaMedSectionView(log: sampleLog, numberFormatter: formatter)
             }
        }
    }
    return PreviewWrapper()
} 