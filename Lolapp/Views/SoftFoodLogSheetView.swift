import SwiftUI
import SwiftData

struct SoftFoodLogSheetView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) var dismissSheet: DismissAction
    
    @Bindable var log: DailyLog
    @State private var gramsToAddText: String = ""
    @State private var targetGramsText: String = ""
    @FocusState private var isKeyboardVisible: Bool
    
    private var foodEntries: [FoodEntry] {
        log.foodEntries ?? []
    }
    
    // Enum to identify focusable fields
    private enum Field: Hashable {
        case targetGrams
        case gramsToAdd
    }
    
    private var foodRemainingGrams: Int {
        log.softFoodTargetGrams - log.softFoodGivenGrams
    }
    
    private var timeFormatter: DateFormatter {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    
    var body: some View {
        NavigationView {
            // Wrap Form in a VStack to apply tap gesture to the whole area
            VStack {
                Form {
                    Section(header: Text("Summary")) {
                        HStack {
                            Text("Target:")
                            Spacer()
                            TextField("Grams", text: $targetGramsText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .fixedSize(horizontal: true, vertical: false)
                                .focused($isKeyboardVisible)
                                .onChange(of: targetGramsText) { _, newValue in onGramsEntered(targetGramsText: newValue) }
                                .onAppear { targetGramsText = String(log.softFoodTargetGrams) }
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
                                .focused($isKeyboardVisible)
                            Button("Add") {
                                addFoodEntry()
                            }
                            .disabled(!isValidInput())
                        }
                    }
                    
                    Section(header: Text("Logged Entries")) {
                        if foodEntries.isEmpty {
                            Text("No food entries logged yet for today.")
                                .foregroundColor(.secondary)
                        } else {
                            List {
                                ForEach(foodEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
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
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isKeyboardVisible = false
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
        
        if log.foodEntries == nil {
            log.foodEntries = []
        }
        log.foodEntries?.append(newFoodEntry)
        
        log.lastModified = Date()
        gramsToAddText = ""
        isKeyboardVisible = false
    }
    
    private func deleteFoodEntry(at offsets: IndexSet) {
        let sortedEntries = foodEntries.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            let entryToDelete = sortedEntries[index]
            
            if let modelIndex = log.foodEntries?.firstIndex(where: { $0.id == entryToDelete.id }) {
                log.foodEntries?.remove(at: modelIndex)
            }
            
            modelContext.delete(entryToDelete)
        }
        log.lastModified = Date()
    }
    
    private func onGramsEntered(targetGramsText: String) {
        let filtered: String = targetGramsText.filter { $0.isNumber }
        if filtered != targetGramsText {
            self.targetGramsText = filtered
            gramsToAddText = filtered
        }
        if let intValue: Int = Int(filtered), intValue > 0 {
            log.softFoodTargetGrams = intValue
            log.lastModified = Date()
        }
    }
    
}

#Preview {
    let config: ModelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer = try! ModelContainer(for: DailyLog.self, FoodEntry.self, configurations: config)
    let sampleLog: DailyLog = DailyLog(date: Date(), softFoodTargetGrams: 280)
    let entry1: FoodEntry = FoodEntry(timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, grams: 50, dailyLog: sampleLog)
    let entry2: FoodEntry = FoodEntry(timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, grams: 70, dailyLog: sampleLog)
    
    if sampleLog.foodEntries == nil {
        sampleLog.foodEntries = []
    }
    sampleLog.foodEntries?.append(entry1)
    sampleLog.foodEntries?.append(entry2)
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
