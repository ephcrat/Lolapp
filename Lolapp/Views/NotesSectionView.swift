import SwiftUI
import SwiftData

struct NotesSectionView: View {
    @Bindable var log: DailyLog
    
    @FocusState private var isTextEditorFocused: Bool
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
        TextEditor(text: notesBinding)
            .frame(minHeight: 100, maxHeight: 200)
            .scrollContentBackground(.hidden)
            .focused($isTextEditorFocused)
    }
}

// --- Preview --- 
#Preview {
    struct PreviewWrapper: View {
        @State private var sampleLogWithNotes: DailyLog = DailyLog(date: Date(), notes: "Ate well today. Seemed calm.")
        @State private var sampleLogNoNotes: DailyLog = DailyLog(date: Date())
        
        var body: some View {
            // Using Form to mimic settings-like appearance for preview
            Form {
                Section("Notes") { // Add a section header for context in preview
                    NotesSectionView(log: sampleLogWithNotes)
                }
                Section("Notes (Empty)") {
                    NotesSectionView(log: sampleLogNoNotes)
                }
            }
        }
    }
    return PreviewWrapper()
} 