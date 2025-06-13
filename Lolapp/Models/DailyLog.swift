import Foundation
import SwiftData

// Enum to represent medication frequency.
// Conforming to Codable makes it easily storable by SwiftData.
// CaseIterable allows us to easily get all cases (e.g., for a Picker).
// Identifiable provides a stable ID (itself in this case) for UI elements like ForEach.
enum Frequency: String, Codable, CaseIterable, Identifiable {
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
// NOTE: CloudKit does not support unique constraints, so we cannot use @Attribute(.unique)
// NOTE: CloudKit requires all attributes to be optional OR have default values. Also requires all relationships to be optional
@Model
final class DailyLog {
    var date: Date = Date()
    
    var coughCount: Int = ModelDefaults.coughCount
    var notes: String? = ModelDefaults.notes
    var softFoodTargetGrams: Int = ModelDefaults.softFoodTargetGrams
    
    // MUST be optional for CloudKit compatibility
    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.dailyLog)
    var foodEntries: [FoodEntry]? = []
    
    // Computed property for total grams of soft food given
    var softFoodGivenGrams: Int {
        foodEntries?.reduce(0) { $0 + $1.grams } ?? 0
    }
    
    // Prednisone specific tracking - add default values
    var isPrednisoneScheduled: Bool = ModelDefaults.isPrednisoneScheduled
    var prednisoneDosageDrops: Int? = ModelDefaults.prednisoneDosageDrops
    var prednisoneFrequency: Frequency? = ModelDefaults.prednisoneFrequency
    var didAdministerPrednisoneDose1: Bool = ModelDefaults.didAdministerPrednisoneDose1
    var didAdministerPrednisoneDose2: Bool? = ModelDefaults.didAdministerPrednisoneDose2
    
    // Asthma Medication specific tracking - add default values
    var asthmaMedDosagePuffs: Int? = ModelDefaults.asthmaMedDosagePuffs
    var asthmaMedFrequency: Frequency? = ModelDefaults.asthmaMedFrequency
    var didAdministerAsthmaMedDose1: Bool = ModelDefaults.didAdministerAsthmaMedDose1
    var didAdministerAsthmaMedDose2: Bool? = ModelDefaults.didAdministerAsthmaMedDose2
    
    var lastModified: Date = Date()
    
    var isAtDefaultState: Bool {
        coughCount == ModelDefaults.coughCount &&
        (notes ?? "").isEmpty &&
        (foodEntries ?? []).isEmpty &&
        softFoodTargetGrams == ModelDefaults.softFoodTargetGrams &&
        isPrednisoneScheduled == ModelDefaults.isPrednisoneScheduled &&
        prednisoneDosageDrops == ModelDefaults.prednisoneDosageDrops &&
        prednisoneFrequency == ModelDefaults.prednisoneFrequency &&
        didAdministerPrednisoneDose1 == ModelDefaults.didAdministerPrednisoneDose1 &&
        (prednisoneFrequency != .twiceADay
         ? didAdministerPrednisoneDose2 == nil
         : didAdministerPrednisoneDose2 == ModelDefaults.didAdministerPrednisoneDose2) &&
        asthmaMedDosagePuffs == ModelDefaults.asthmaMedDosagePuffs &&
        asthmaMedFrequency == ModelDefaults.asthmaMedFrequency &&
        didAdministerAsthmaMedDose1 == ModelDefaults.didAdministerAsthmaMedDose1 &&
        (asthmaMedFrequency != .twiceADay
         ? didAdministerAsthmaMedDose2 == nil
         : didAdministerAsthmaMedDose2 == ModelDefaults.didAdministerAsthmaMedDose2)
    }
    
    init(date: Date = Date(),
         coughCount: Int = ModelDefaults.coughCount,
         notes: String? = ModelDefaults.notes,
         foodEntries: [FoodEntry] = [],
         softFoodTargetGrams: Int = ModelDefaults.softFoodTargetGrams,
         isPrednisoneScheduled: Bool = ModelDefaults.isPrednisoneScheduled,
         prednisoneDosageDrops: Int? = ModelDefaults.prednisoneDosageDrops,
         prednisoneFrequency: Frequency? = ModelDefaults.prednisoneFrequency,
         didAdministerPrednisoneDose1: Bool = ModelDefaults.didAdministerPrednisoneDose1,
         didAdministerPrednisoneDose2: Bool? = ModelDefaults.didAdministerPrednisoneDose2,
         asthmaMedDosagePuffs: Int? = ModelDefaults.asthmaMedDosagePuffs,
         asthmaMedFrequency: Frequency? = ModelDefaults.asthmaMedFrequency,
         didAdministerAsthmaMedDose1: Bool = ModelDefaults.didAdministerAsthmaMedDose1,
         didAdministerAsthmaMedDose2: Bool? = ModelDefaults.didAdministerAsthmaMedDose2,
         lastModified: Date = Date()
    ) {
        // Normalize the date to midnight (start of the day) for consistency.
        // This prevents issues where logs for the same calendar day might
        // have slightly different timestamps.
        self.date = Calendar.current.startOfDay(for: date)
        self.coughCount = coughCount
        self.notes = notes
        self.foodEntries = foodEntries
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
        self.init(date: Date())
    }
}
