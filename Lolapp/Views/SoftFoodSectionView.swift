import SwiftUI
import SwiftData

struct SoftFoodSectionView: View {
    @Bindable var log: DailyLog
    
    // State for the text field input
    @State private var foodToAddText: String = ""
    
    // Calculated remaining amount uses the log's target
    private var foodRemainingGrams: Int {
        log.softFoodTargetGrams - log.softFoodGivenGrams
    }
    
    var body: some View {
        // Use DisclosureGroup for collapsibility
        DisclosureGroup("Soft Food Intake") { // Title becomes the label
            // The existing content goes inside the DisclosureGroup
            VStack(alignment: .leading) {
                // Display and Edit Target
                HStack {
                    Text("Target:")
                    Spacer()
                    // Use TextField for editing, bound to the log's property
                    TextField("Target grams", value: $log.softFoodTargetGrams, formatter: numberFormatter)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: true, vertical: false) // Prevent TextField from expanding excessively
                     Text("g") // Add 'g' suffix
                }
                .foregroundColor(.secondary)
                
                // Display Given
                HStack {
                    Text("Given:")
                    Spacer()
                    Text("\(log.softFoodGivenGrams)g")
                        .fontWeight(.semibold)
                }
                
                // Display Remaining
                 HStack {
                    Text("Remaining:")
                    Spacer()
                    Text("\(foodRemainingGrams)g")
                         .fontWeight(foodRemainingGrams < 0 ? .bold : .regular) // Bold if negative
                         .foregroundColor(foodRemainingGrams < 0 ? .red : .primary) // Red if negative
                }
                
                Divider().padding(.vertical, 5)
                
                // Input Row for adding food
                HStack {
                    TextField("Grams to add", text: $foodToAddText)
                        .keyboardType(.numberPad)
                    
                    Button("Add Food") {
                        addFood()
                    }
                    .disabled(!isValidInput())
                }
            }
        }
        // .padding(.bottom)
    }
    
    /// Checks if the input text is a valid positive integer.
    private func isValidInput() -> Bool {
        guard let amount = Int(foodToAddText), amount > 0 else {
            return false
        }
        return true
    }
    
    /// Adds the entered food amount to the log.
    private func addFood() {
        guard let amount = Int(foodToAddText), amount > 0 else {
            // Should not happen if button is disabled correctly, but good practice
            return
        }
        
        log.softFoodGivenGrams += amount
        // Clear the text field after adding
        foodToAddText = ""
    }
}

// --- Preview --- 
#Preview {
    struct PreviewWrapper: View {
        // Sample log can now include a target
        @State private var sampleLog = DailyLog(date: Date(), softFoodGivenGrams: 120, softFoodTargetGrams: 280)
        
        var body: some View {
             List { 
                 SoftFoodSectionView(log: sampleLog)
             }
        }
    }
    return PreviewWrapper()
} 