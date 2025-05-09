import Foundation
import SwiftData

// Enum to represent medication frequency.
// Conforming to Codable makes it easily storable by SwiftData.
// CaseIterable allows us to easily get all cases (e.g., for a Picker).
// Identifiable provides a stable ID (itself in this case) for UI elements like ForEach.
enum Frequency: Codable, CaseIterable, Identifiable {
    case onceADay
    case twiceADay

    // Provides a stable ID for use in SwiftUI Pickers
    var id: Self { self }

    // User-friendly display name for UI presentation
    var displayName: String {
        switch self {
        case .onceADay:
            return "Once a day"
        case .twiceADay:
            return "Twice a day"
        }
    }
}

// The @Model macro tells SwiftData to manage this class.
// It automatically handles persistence (saving/loading to disk)
// and generates the necessary database schema. `final class` means
// this class cannot be subclassed, which is common for models.
@Model
final class DailyLog {
    // Unique identifier for each log entry, tied to the specific day.
    // Using @Attribute(.unique) ensures SwiftData enforces that
    // no two DailyLog objects can have the same 'date' value.
    @Attribute(.unique) var date: Date

    // Tracking variables - initialized with default values in the init.
    var coughCount: Int
    var notes: String? // String? means it's an optional String, can be nil.
    var softFoodGivenGrams: Int
    var softFoodTargetGrams: Int

    // Prednisone specific tracking
    var isPrednisoneScheduled: Bool
    var prednisoneDosageDrops: Int?
    var prednisoneFrequency: Frequency?
    var didAdministerPrednisoneDose1: Bool
    var didAdministerPrednisoneDose2: Bool?

    // Asthma Medication specific tracking
    var asthmaMedDosagePuffs: Int?
    var asthmaMedFrequency: Frequency?
    var didAdministerAsthmaMedDose1: Bool
    var didAdministerAsthmaMedDose2: Bool?

    // Timestamp for CloudKit conflict resolution. SwiftData uses this
    // field when syncing with iCloud to determine which version of the
    // data is newer if changes were made on multiple devices.
    var lastModified: Date

    // Initializer (constructor) to create a new DailyLog instance.
    // It takes a 'date' and provides default values for all other properties
    init(date: Date,
         coughCount: Int = 0,
         notes: String? = nil,
         softFoodGivenGrams: Int = 0,
         softFoodTargetGrams: Int = 300,
         isPrednisoneScheduled: Bool = false,
         prednisoneDosageDrops: Int? = nil,
         prednisoneFrequency: Frequency? = nil,
         didAdministerPrednisoneDose1: Bool = false,
         didAdministerPrednisoneDose2: Bool? = false,
         asthmaMedDosagePuffs: Int? = 3,
         asthmaMedFrequency: Frequency? = .onceADay,
         didAdministerAsthmaMedDose1: Bool = false,
         didAdministerAsthmaMedDose2: Bool? = false,
         lastModified: Date = Date()
    ) {
        // Normalize the date to midnight (start of the day) for consistency.
        // This prevents issues where logs for the same calendar day might
        // have slightly different timestamps.
        self.date = Calendar.current.startOfDay(for: date)
        self.coughCount = coughCount
        self.notes = notes
        self.softFoodGivenGrams = softFoodGivenGrams
        self.softFoodTargetGrams = softFoodTargetGrams
        self.isPrednisoneScheduled = isPrednisoneScheduled
        self.prednisoneDosageDrops = prednisoneDosageDrops
        self.prednisoneFrequency = prednisoneFrequency
        self.didAdministerPrednisoneDose1 = didAdministerPrednisoneDose1
        // Important: We only care about the state of Dose 2 if the frequency
        // *is* twice a day. If it's once a day, this Bool? should remain nil
        // or be treated as irrelevant. We ensure it's nil if not twice a day.
        self.didAdministerPrednisoneDose2 = (prednisoneFrequency == .twiceADay) ? didAdministerPrednisoneDose2 : nil

        self.asthmaMedDosagePuffs = asthmaMedDosagePuffs
        self.asthmaMedFrequency = asthmaMedFrequency
        self.didAdministerAsthmaMedDose1 = didAdministerAsthmaMedDose1
        self.didAdministerAsthmaMedDose2 = (asthmaMedFrequency == .twiceADay) ? didAdministerAsthmaMedDose2 : nil
        self.lastModified = lastModified

        // Note: SwiftData automatically updates `lastModified` when any
        // property changes AFTER the object has been saved once.
        // We set it initially here.
    }

     // Convenience initializer: A simpler way to create a DailyLog for *today*.
     // It calls the main `init` method, passing in the current date.
     // This is useful for quickly creating a log entry for the present day.
     convenience init() {
         self.init(date: Date()) // Still uses defaults, including target=300
     }
}