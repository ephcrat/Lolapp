import SwiftUI
import SwiftData

struct PrednisoneSectionView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter
    @Binding var isExpanded: Bool
    let focusedField: FocusState<FocusedField?>.Binding
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                PrednisoneDetailsView(log: log, numberFormatter: numberFormatter, focusedField: focusedField)
            },
            label: {
                Label("Prednisone", systemImage: "eyedropper.halffull")
            }
        )
    }
}

private struct PrednisoneDetailsView: View {
    @Bindable var log: DailyLog
    let numberFormatter: NumberFormatter
    let focusedField: FocusState<FocusedField?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) { // Use VStack to space out GroupBoxes
            GroupBox(label: Text("SETUP").font(.caption).foregroundColor(.secondary)) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Schedule Prednisone?", isOn: $log.isPrednisoneScheduled)
                        .padding(.trailing) 
                        .onChange(of: log.isPrednisoneScheduled) { _, isScheduled in
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
                    
                    if log.isPrednisoneScheduled {
                        HStack {
                            Text("Dosage (drops):")
                            Spacer()
                            TextField("Optional", value: $log.prednisoneDosageDrops, formatter: numberFormatter)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                                .focused(focusedField, equals: .prednisoneDosage)
                        }
                        
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
                    }
                }
                .padding(.top, 5)
                
            }
            
            if log.isPrednisoneScheduled && log.prednisoneFrequency != nil {
                GroupBox(label: Text("ADMINISTRATION").font(.caption).foregroundColor(.secondary)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Administered Dose 1", isOn: $log.didAdministerPrednisoneDose1)
                            .toggleStyle(.switch)
                            .padding(.trailing)
                        
                        if log.prednisoneFrequency == .twiceADay {
                            let dose2Binding: Binding<Bool> = Binding<Bool>(
                                get: { log.didAdministerPrednisoneDose2 ?? false },
                                set: { newValue in log.didAdministerPrednisoneDose2 = newValue }
                            )
                            
                            Toggle("Administered Dose 2", isOn: dose2Binding)
                                .toggleStyle(.switch)
                                .padding(.trailing)
                                .transition(.opacity.combined(with: .slide))
                        }
                    }
                    .padding(.top, 5)
                }
                .animation(.default, value: log.prednisoneFrequency)
                
            }
        }
        .padding(.leading, -16)
        .animation(.smooth, value: log.isPrednisoneScheduled)
    }
}

#Preview { 
    struct PreviewWrapper: View {
        @State private var sampleLogIsPrednisoneScheduled = DailyLog(date: Date(), isPrednisoneScheduled: true, prednisoneFrequency: .twiceADay)
        @State private var sampleLogNotPrednisoneScheduled = DailyLog(date: Date(), isPrednisoneScheduled: false)
        @State private var isExpanded1: Bool = true
        @State private var isExpanded2: Bool = true // So we can see the not scheduled state too
        let formatter: NumberFormatter = numberFormatter
        @FocusState private var focusedField: FocusedField?
        
        var body: some View {
            List { // Use List to see DisclosureGroup in a list context
                PrednisoneSectionView(log: sampleLogIsPrednisoneScheduled, numberFormatter: formatter, isExpanded: $isExpanded1, focusedField: $focusedField)
                PrednisoneSectionView(log: sampleLogNotPrednisoneScheduled, numberFormatter: formatter, isExpanded: $isExpanded2, focusedField: $focusedField)
            }
            .listStyle(.insetGrouped)
        }
    }
    return PreviewWrapper()
} 
