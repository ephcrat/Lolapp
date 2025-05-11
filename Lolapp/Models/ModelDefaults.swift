import Foundation

// Global constants for default values used in the DailyLog model
// and related logic.

struct ModelDefaults {
    static let coughCount: Int = 0
    static let notes: String? = nil
    static let softFoodTargetGrams: Int = 300
    
    // Prednisone Defaults
    static let isPrednisoneScheduled: Bool = false
    static let prednisoneDosageDrops: Int? = nil
    static let prednisoneFrequency: Frequency? = nil
    static let didAdministerPrednisoneDose1: Bool = false
    static let didAdministerPrednisoneDose2: Bool? = nil // Note: Actual nil state depends on frequency
    
    // Asthma Medication Defaults
    static let asthmaMedDosagePuffs: Int? = 3
    static let asthmaMedFrequency: Frequency? = .onceADay
    static let didAdministerAsthmaMedDose1: Bool = false
    static let didAdministerAsthmaMedDose2: Bool? = nil
} 