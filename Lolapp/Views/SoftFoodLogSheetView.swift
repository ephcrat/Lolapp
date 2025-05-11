import SwiftUI
import SwiftData

struct SoftFoodLogSheetView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) var dismissSheet: DismissAction
    
    @Bindable var log: DailyLog
    @State private var gramsToAddText: String = ""

    private var foodRemainingGrams: Int {
        log.softFoodTargetGrams - log.softFoodGivenGrams
    }

    // Date formatter for the food entry time
    private var timeFormatter: DateFormatter {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private var entryNumberFormatter: NumberFormatter {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 1 // Food entry must be at least 1 gram
        formatter.allowsFloats = false
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Target, Given, Remaining Section (using Form for grouping)
                Form {
                    Section(header: Text("Summary")) {
                        HStack {
                            Text("Target:")
                            Spacer()
                            TextField("Grams", value: $log.softFoodTargetGrams, formatter: numberFormatter)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .fixedSize(horizontal: true, vertical: false)
                            Text("g")
                        }
                        HStack {
                            Text("Given:")
                            Spacer()
                            Text("\(log.softFoodGivenGrams)g").fontWeight(.semibold)
                        }
                        HStack {
                            Text("Remaining:")
                            Spacer()
                            Text("\(foodRemainingGrams)g")
                                .fontWeight(foodRemainingGrams < 0 ? .bold : .regular)
                                .foregroundColor(foodRemainingGrams < 0 ? .red : .primary)
                        }
                    }
                    
                    Section(header: Text("Add New Entry")) {
                        HStack {
                            TextField("Grams to add", text: $gramsToAddText)
                                .keyboardType(.numberPad)
                            Button("Add") {
                                addFoodEntry()
                            }
                            .disabled(!isValidInput())
                        }
                    }

                    Section(header: Text("Logged Entries")) {
                        if log.foodEntries.isEmpty {
                            Text("No food entries logged yet for today.")
                                .foregroundColor(.secondary)
                        } else {
                            List {
                                ForEach(log.foodEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                                    HStack {
                                        Text("\(entry.grams)g")
                                        Spacer()
                                        Text(timeFormatter.string(from: entry.timestamp))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .onDelete(perform: deleteFoodEntry)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Soft Food Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismissSheet()
                    }
                }
            }
        }
    }

    private func isValidInput() -> Bool {
        guard let amount = Int(gramsToAddText), amount > 0 else {
            return false
        }
        return true
    }
    
    private func addFoodEntry() {
        guard let grams = Int(gramsToAddText), grams > 0 else { return }
        
        let newFoodEntry = FoodEntry(timestamp: Date(), grams: grams, dailyLog: log)
        log.foodEntries.append(newFoodEntry)
        log.lastModified = Date()
        gramsToAddText = ""
    }

    private func deleteFoodEntry(at offsets: IndexSet) {
        let sortedEntries = log.foodEntries.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            let entryToDelete = sortedEntries[index]
            if let originalIndex = log.foodEntries.firstIndex(where: { $0.id == entryToDelete.id }) {
                let entryBeingDeleted = log.foodEntries.remove(at: originalIndex)
                modelContext.delete(entryBeingDeleted)
            }
        }
        log.lastModified = Date()
    }
}

#Preview {
    let config: ModelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer = try! ModelContainer(for: DailyLog.self, FoodEntry.self, configurations: config)
    let sampleLog: DailyLog = DailyLog(date: Date(), softFoodTargetGrams: 280)
    let entry1: FoodEntry = FoodEntry(timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, grams: 50, dailyLog: sampleLog)
    let entry2: FoodEntry = FoodEntry(timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, grams: 70, dailyLog: sampleLog)
    sampleLog.foodEntries.append(entry1)
    sampleLog.foodEntries.append(entry2)
    container.mainContext.insert(sampleLog)

    struct PreviewHost: View {
        @State var showSheet: Bool = true
        var logForSheet: DailyLog
        var body: some View {
            VStack { Text("Preview Host Content") }
            .sheet(isPresented: $showSheet) {
                SoftFoodLogSheetView(log: logForSheet)
            }
        }
    }
    return PreviewHost(logForSheet: sampleLog)
        .modelContainer(container)
} 