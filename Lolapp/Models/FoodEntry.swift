import Foundation
import SwiftData

@Model
final class FoodEntry {
    var timestamp: Date
    var grams: Int
    
    // Link back to the DailyLog
    // This creates a many-to-one relationship: many FoodEntry instances can belong to one DailyLog.
    // SwiftData will automatically manage the inverse (one-to-many) relationship on DailyLog
    var dailyLog: DailyLog?

    init(timestamp: Date = Date(), grams: Int = 0, dailyLog: DailyLog? = nil) {
        self.timestamp = timestamp
        self.grams = grams
        self.dailyLog = dailyLog
    }
} 