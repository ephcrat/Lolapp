import SwiftUI
import SwiftData

struct AsthmaMedSectionView: View {
    // Use @Bindable to receive the mutable log object from the parent view
    @Bindable var log: DailyLog
    // Receive the formatter from the parent view (assuming puffs are whole numbers too)
    let numberFormatter: NumberFormatter 
    
    var body: some View {
        // Use DisclosureGroup for collapsibility
        DisclosureGroup("Asthma Medication") { // Title becomes the label
            // The existing content goes inside the DisclosureGroup
            VStack(alignment: .leading) {
                // --- Main Toggle --- 
                Toggle("Schedule Asthma Med?", isOn: $log.isAsthmaMedScheduled)
                    .padding(.trailing)
                    .onChange(of: log.isAsthmaMedScheduled) { _, isScheduled in
                        handleScheduleToggle(isScheduled)
                    }

                // --- Conditional Details --- 
                if log.isAsthmaMedScheduled {
                    // Use the helper view for the details
                    AsthmaMedDetailsView(log: log, numberFormatter: numberFormatter)
                }
            } // End outer VStack wrapper
            // Apply animation here to the showing/hiding of details view
             .animation(.default, value: log.isAsthmaMedScheduled)
        }
    }

    // Helper function to contain toggle logic
    private func handleScheduleToggle(_ isScheduled: Bool) {
        if isScheduled {
            if log.asthmaMedFrequency == nil { log.asthmaMedFrequency = .onceADay } // Default frequency
            if log.asthmaMedFrequency != .twiceADay { log.didAdministerAsthmaMedDose2 = nil }
        } else {
            log.asthmaMedDosagePuffs = nil
            log.asthmaMedFrequency = nil
            log.didAdministerAsthmaMedDose1 = false
            log.didAdministerAsthmaMedDose2 = nil
        }
    }
}

// --- Private Helper View for Asthma Med Details --- 
private struct AsthmaMedDetailsView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading) { // Group conditional controls
            // Dosage Input (Puffs)
            HStack {
                Text("Dosage (puffs):") // Changed label
                Spacer()
                TextField("Optional", value: $log.asthmaMedDosagePuffs, formatter: numberFormatter) // Use puffs property
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
            
            // Frequency Picker
            Picker("Frequency:", selection: $log.asthmaMedFrequency) { // Use asthma frequency
                Text("Not Set").tag(nil as Frequency?)
                ForEach(Frequency.allCases) { freq in
                    Text(freq.displayName).tag(freq as Frequency?)
                }
            }
            .onChange(of: log.asthmaMedFrequency) { _, newFrequency in // Use asthma frequency
                if newFrequency != .twiceADay {
                    log.didAdministerAsthmaMedDose2 = nil // Use asthma dose 2 status
                }
            }
            
            // Admin Checkboxes / Switches
            Divider().padding(.vertical, 5)
            Toggle("Administered Dose 1", isOn: $log.didAdministerAsthmaMedDose1) // Use asthma dose 1
                .toggleStyle(.switch) // Use switch style
                .padding(.trailing)
                
            // Conditionally show Dose 2 Checkbox/Switch
            if log.asthmaMedFrequency == .twiceADay { // Use asthma frequency
                // Create a custom binding for Dose 2
                let dose2Binding = Binding<Bool>(
                    get: { log.didAdministerAsthmaMedDose2 ?? false }, // Use asthma dose 2
                    set: { newValue in log.didAdministerAsthmaMedDose2 = newValue } // Use asthma dose 2
                )
                
                Toggle("Administered Dose 2", isOn: dose2Binding)
                    .toggleStyle(.switch) // Use switch style
                    .padding(.trailing)
                    .transition(.opacity.combined(with: .slide))
            }
        }
         // Animation applied to changes within this view triggered by frequency
        .animation(.default, value: log.asthmaMedFrequency) // Use asthma frequency
    }
}

// --- Preview for AsthmaMedSectionView ---
#Preview { 
    struct PreviewWrapper: View {
        @State private var sampleLog = DailyLog(date: Date(), isAsthmaMedScheduled: true, asthmaMedFrequency: .onceADay) // Use asthma properties
        
        // Access the global numberFormatter or define one locally for preview
        let formatter = numberFormatter 
        
        var body: some View {
             List { 
                 AsthmaMedSectionView(log: sampleLog, numberFormatter: formatter)
             }
        }
    }
    return PreviewWrapper()
} 