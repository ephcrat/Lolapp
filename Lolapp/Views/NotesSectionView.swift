import SwiftUI
import SwiftData

struct NotesSectionView: View {
    @Bindable var log: DailyLog
    let focusedField: FocusState<FocusedField?>.Binding
    
    private var notesBinding: Binding<String> {
        Binding<String>(
            get: { log.notes ?? "" },
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
            .focused(focusedField, equals: .notes)
    }
}

// --- Preview --- 
#Preview {
    struct PreviewWrapper: View {
        @State private var sampleLogWithNotes: DailyLog = DailyLog(date: Date(), notes: "Ate well today. Seemed calm.")
        @State private var sampleLogNoNotes: DailyLog = DailyLog(date: Date())
        @FocusState private var focusedField: FocusedField?
        
        var body: some View {
            // Using Form to mimic settings-like appearance for preview
            Form {
                Section("Notes") {
                    NotesSectionView(log: sampleLogWithNotes, focusedField: $focusedField)
                }
                Section("Notes (Empty)") {
                    NotesSectionView(log: sampleLogNoNotes, focusedField: $focusedField)
                }
            }
        }
    }
    return PreviewWrapper()
} 