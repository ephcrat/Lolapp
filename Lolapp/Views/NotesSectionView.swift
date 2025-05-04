import SwiftUI
import SwiftData

struct NotesSectionView: View {
    @Bindable var log: DailyLog
    
    // Custom binding to handle the optional String for TextEditor
    private var notesBinding: Binding<String> {
        Binding<String>(
            get: { log.notes ?? "" }, // Return empty string if notes is nil
            set: { newValue in
                // Only set to nil if the new value is truly empty,
                // otherwise update with the new string.
                // This prevents storing empty strings when the user clears the editor.
                log.notes = newValue.isEmpty ? nil : newValue
            }
        )
    }
    
    var body: some View {
        DisclosureGroup("Notes") {
            // TextEditor needs a non-optional String binding
            TextEditor(text: notesBinding)
                .frame(height: 150) // Set a reasonable default height
                .border(Color.secondary.opacity(0.2), width: 1) // Subtle border
                .padding(.top, 5) // Add space above editor
        }
    }
}

// --- Preview --- 
#Preview {
    struct PreviewWrapper: View {
        @State private var sampleLogWithNotes = DailyLog(date: Date(), notes: "Ate well today. Seemed calm.")
        @State private var sampleLogNoNotes = DailyLog(date: Date())
        
        var body: some View {
            List {
                NotesSectionView(log: sampleLogWithNotes)
                NotesSectionView(log: sampleLogNoNotes)
            }
        }
    }
    return PreviewWrapper()
} 