import SwiftUI
import SwiftData

struct PrednisoneSectionView: View {
    // Use @Bindable to receive the mutable log object from the parent view
    @Bindable var log: DailyLog
    // Receive the formatter from the parent view
    let numberFormatter: NumberFormatter
    
    var body: some View {
        // Use DisclosureGroup for collapsibility
        DisclosureGroup("Prednisone") { // Title becomes the label
            // The existing content goes inside the DisclosureGroup
            VStack(alignment: .leading) {
                // --- Main Toggle --- 
                Toggle("Schedule Prednisone?", isOn: $log.isPrednisoneScheduled)
                    .padding(.trailing)
                    .onChange(of: log.isPrednisoneScheduled) { _, isScheduled in
                        handleScheduleToggle(isScheduled)
                    }

                // --- Conditional Details --- 
                if log.isPrednisoneScheduled {
                    PrednisoneDetailsView(log: log, numberFormatter: numberFormatter)
                }
            }
             .animation(.default, value: log.isPrednisoneScheduled) // Animation stays on the content
        }.padding(.bottom)
    }

    // Helper function to contain toggle logic
    private func handleScheduleToggle(_ isScheduled: Bool) {
        if isScheduled {
            if log.prednisoneFrequency == nil { log.prednisoneFrequency = .onceADay }
            if log.prednisoneFrequency != .twiceADay { log.didAdministerPrednisoneDose2 = nil }
        } else {
            log.prednisoneDosageDrops = nil
            log.prednisoneFrequency = nil
            log.didAdministerPrednisoneDose1 = false
            log.didAdministerPrednisoneDose2 = nil
        }
    }
}

// --- Private Helper View for Prednisone Details --- 
private struct PrednisoneDetailsView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading) { // Group conditional controls
            // Dosage Input
            HStack {
                Text("Dosage (drops):")
                Spacer()
                TextField("Optional", value: $log.prednisoneDosageDrops, formatter: numberFormatter)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            
            // Frequency Picker
            Picker("Frequency:", selection: $log.prednisoneFrequency) {
                Text("Not Set").tag(nil as Frequency?)
                ForEach(Frequency.allCases) { freq in
                    Text(freq.displayName).tag(freq as Frequency?)
                }
            }
            .onChange(of: log.prednisoneFrequency) { _, newFrequency in
                if newFrequency != .twiceADay {
                    log.didAdministerPrednisoneDose2 = nil
                }
            }
            
            // Admin Checkboxes
            Divider().padding(.vertical, 5)
            Toggle("Administered Dose 1", isOn: $log.didAdministerPrednisoneDose1)
                .toggleStyle(.switch)
                .padding(.trailing) // Add padding
                
            // Conditionally show Dose 2 Checkbox
            if log.prednisoneFrequency == .twiceADay {
                // Create a custom binding to bridge Binding<Bool?> to Binding<Bool>
                let dose2Binding: Binding<Bool> = Binding<Bool>(
                    get: { log.didAdministerPrednisoneDose2 ?? false }, // Read: return value or false if nil
                    set: { newValue in log.didAdministerPrednisoneDose2 = newValue } // Write: update the optional Bool
                )
                
                Toggle("Administered Dose 2", isOn: dose2Binding) // Use the custom binding
                    .toggleStyle(.switch)
                    .padding(.trailing) // Add padding
                    // Animation applied specifically to this toggle's appearance
                    .transition(.opacity.combined(with: .slide))
            }
        }
         // Animation applied to changes within this view triggered by frequency
        .animation(.default, value: log.prednisoneFrequency)
    }
}

// Add a specific preview for this section if desired (optional)
#Preview { 
    // Need a dummy log and context for previewing this isolated section
    struct PreviewWrapper: View {
        @State private var sampleLog: DailyLog = DailyLog(date: Date(), isPrednisoneScheduled: true, prednisoneFrequency: .twiceADay)
        let formatter: NumberFormatter = NumberFormatter() // Simple formatter for preview
        
        var body: some View {
             NavigationView { // Or just List/Form for structure
                 List { // List provides section styling
                     PrednisoneSectionView(log: sampleLog, numberFormatter: formatter)
                 }
             }
        }
    }
    return PreviewWrapper()
} 