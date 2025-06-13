import SwiftUI
import SwiftData


struct AsthmaMedSectionView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter 
    @Binding var isExpanded: Bool
    let focusedField: FocusState<FocusedField?>.Binding
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                AsthmaMedDetailsView(log: log, numberFormatter: numberFormatter, focusedField: focusedField)
            },
            label: {
                Label("Asthma Medication", systemImage: "lungs.fill")
            }
        )
    }
}

private struct AsthmaMedDetailsView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter
    let focusedField: FocusState<FocusedField?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox(label: Text("SETUP").font(.caption).foregroundColor(.secondary)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Dosage (puffs):")
                        Spacer()
                        TextField("Optional", value: $log.asthmaMedDosagePuffs, formatter: numberFormatter)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                            .focused(focusedField, equals: .asthmaPuffs)
                    }
                    
                    Picker("Frequency:", selection: $log.asthmaMedFrequency) { 
                        Text("Not Set").tag(nil as Frequency?)
                        ForEach(Frequency.allCases) { freq in
                            Text(freq.displayName).tag(freq as Frequency?)
                        }
                    }
                    .onChange(of: log.asthmaMedFrequency) { _, newFrequency in 
                        if newFrequency == nil {
                            log.didAdministerAsthmaMedDose1 = false
                            log.didAdministerAsthmaMedDose2 = nil
                        } else if newFrequency != .twiceADay {
                            log.didAdministerAsthmaMedDose2 = nil 
                        }
                    }
                }
                .padding(.top, 5)
            }
            
            if log.asthmaMedFrequency != nil {
                GroupBox(label: Text("ADMINISTRATION").font(.caption).foregroundColor(.secondary)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Administered Dose 1", isOn: $log.didAdministerAsthmaMedDose1)
                            .toggleStyle(.switch)
                            .padding(.trailing)
                        
                        if log.asthmaMedFrequency == .twiceADay { 
                            let dose2Binding: Binding<Bool> = Binding<Bool>(
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
                    .padding(.top, 5)
                }
            }
        }
        .padding(.leading, -16)
    }
}

#Preview { 
    struct PreviewWrapper: View {
        @State private var sampleLogAsthmaScheduled: DailyLog = DailyLog(date: Date(), asthmaMedDosagePuffs: 2, asthmaMedFrequency: .twiceADay, didAdministerAsthmaMedDose1: false)
        @State private var sampleLogAsthmaNotScheduled: DailyLog = DailyLog(date: Date(), asthmaMedFrequency: nil)
        @State private var isExpanded1: Bool = true
        @State private var isExpanded2: Bool = true
        @FocusState private var focusedField: FocusedField?
        let formatter: NumberFormatter = numberFormatter 
        var body: some View {
            List { 
                AsthmaMedSectionView(log: sampleLogAsthmaScheduled, numberFormatter: formatter, isExpanded: $isExpanded1, focusedField: $focusedField)
                AsthmaMedSectionView(log: sampleLogAsthmaNotScheduled, numberFormatter: formatter, isExpanded: $isExpanded2, focusedField: $focusedField)
            }
            .listStyle(.insetGrouped)
        }
    }
    return PreviewWrapper()
} 
