# Lolapp

**Core Goal:** To provide a simple, reliable, local-first mobile application for tracking a cat's asthma symptoms (coughing), prednisone medication schedule/administration, asthma medication schedule/administration, soft food intake, daily care tasks, and relevant notes, with seamless cloud synchronization for data backup and potential multi-device access.

**I. Data Model Design**

The core data entity is `DailyLog`, representing all tracked information for a single calendar day.

- **`DailyLog` Entity (@Model for SwiftData):**

  - `date`: `Date` (Primary identifier for the day. Normalized to the start of the day).
  - `coughCount`: `Int` (Number of coughs observed. Default: 0).
  - `notes`: `String?` (Optional: Free-form text observations. Default: nil or empty).
  - `lastModified`: `Date` (Timestamp for CloudKit conflict resolution).

  - **Prednisone Tracking:**

    - `isPrednisoneScheduled`: `Bool` (Is prednisone scheduled for this day? Default: false).
    - `prednisoneDosageDrops`: `Int?` (Optional: Number of drops per dose. Relevant if scheduled).
    - `prednisoneFrequency`: `Enum?` (Optional: `.onceADay`, `.twiceADay`. Relevant if scheduled).
    - `didAdministerPrednisoneDose1`: `Bool` (Was the first/only dose given? Default: false).
    - `didAdministerPrednisoneDose2`: `Bool?` (Optional: Was the second dose given? Relevant if scheduled for twice daily. Default: nil or false).

  - **Asthma Medication (AeroChamber) Tracking:**

    - `asthmaMedDosagePuffs`: `Int?` (Optional: Number of puffs per dose. Relevant if scheduled).
    - `asthmaMedFrequency`: `Enum?` (Optional: `.onceADay`, `.twiceADay`. Relevant if scheduled).
    - `didAdministerAsthmaMedDose1`: `Bool` (Was the first/only dose given? Default: false).
    - `didAdministerAsthmaMedDose2`: `Bool?` (Optional: Was the second dose given? Relevant if scheduled for twice daily. Default: nil or false).

  - **Food Tracking:**
    - `softFoodTargetGrams`: `Int` (User-defined target for daily soft food intake. Default: 300g).
    - `foodEntries`: `[FoodEntry]` (A list of individual food entries. See `FoodEntry` model below).
    - `softFoodGivenGrams`: `Int` (Computed property: Sum of grams from all `foodEntries` for the day).

- **`FoodEntry` Entity (@Model for SwiftData):**
  - `timestamp`: `Date` (Time the food was logged).
  - `grams`: `Int` (Amount of food given in this entry).
  - `dailyLog`: `DailyLog?` (Relationship linking back to the parent `DailyLog`).

**II. User Interface (UI) & User Experience (UX) Flow**

Focus on simplicity and clarity across two main views.

1.  **Main View: Calendar Dashboard**

    - **Layout:** Monthly calendar grid, navigable between months.
    - **Cells (Days):**
      - **Background:** Opacity/Color maps to `coughCount`.
      - **Indicator Dot (Prednisone):** If `isPrednisoneScheduled` is true.
      - **Today's Date:** Clearly highlighted.
    - **Interaction:** Tap day cell -> `Day Detail View`.
    - **Quick Action:** "+ Cough" button for today's log (Implemented in `CalendarView`).

2.  **Day Detail View (`DayDetailView.swift`)**

    - **Context:** Selected `date` displayed prominently.
    - **Layout:** Organized into logical sections within a `ScrollView`. An `activeLog` (either existing or temporary) is used for data binding. Logic exists to create or delete `DailyLog` instances based on whether data is default or not.
    - **Sections:**
      - **Cough Tracking (`CoughTrackingSectionView.swift`):**
        - Display: Current `coughCount`.
        - Controls: "+/-" buttons to modify `coughCount`.
      - **Prednisone Schedule & Status (`PrednisoneSectionView.swift`):**
        - Control: Toggle "Schedule Prednisone?". Binds to `isPrednisoneScheduled`.
        - Conditional Controls (If ON): Input for `prednisoneDosageDrops`, Picker for `prednisoneFrequency`.
      - **Asthma Medication Schedule & Status (`AsthmaMedSectionView.swift`):**
        - Controls: Input for `asthmaMedDosagePuffs`, Picker for `asthmaMedFrequency`.
      - **Daily Tasks / Medication Administration (Checklist - part of medication sections):**
        - _Prednisone:_
          - Checkbox: "Administered Dose 1". Binds to `didAdministerPrednisoneDose1`.
          - Checkbox: "Administered Dose 2". Binds to `didAdministerPrednisoneDose2` (visible if frequency is `.twiceADay`).
        - _Asthma Medication:_
          - Checkbox: "Administered Dose 1". Binds to `didAdministerAsthmaMedDose1`.
          - Checkbox: "Administered Dose 2". Binds to `didAdministerAsthmaMedDose2` (visible if frequency is `.twiceADay`).
      - **Soft Food Intake:**
        - UI: A tappable row labeled "Soft Food Intake" with an icon (e.g., `fork.knife`).
        - Display: Shows a summary like "Given [X]g / Target [Y]g".
        - Interaction: Tapping the row presents a bottom sheet (`SoftFoodLogSheetView.swift`).
      - **Notes (`NotesSectionView.swift`):**
        - Input: Multi-line `TextEditor` bound to `notes`.
    - **Interaction:** Auto-save changes via SwiftData bindings. Navigate back to Calendar.

3.  **Soft Food Log Sheet (`SoftFoodLogSheetView.swift`)**
    - Presented as a bottom sheet from the "Soft Food Intake" row in `DayDetailView`.
    - **Layout:** `NavigationView` with sections in a `Form`.
    - **Sections:**
      - **Summary:**
        - Editable `TextField` for `softFoodTargetGrams`.
        - Display for computed `softFoodGivenGrams`.
        - Display for `foodRemainingGrams`.
      - **Add New Entry:**
        - `TextField` to input grams for a new food entry.
        - "Add" button to create and append a new `FoodEntry` to the `DailyLog.foodEntries` list (updates are reflected immediately).
      - **Logged Entries:**
        - `List` displaying each `FoodEntry` (grams and timestamp).
        - Swipe-to-delete functionality for each entry.
    - **Interaction:** "Done" button to dismiss the sheet.

**III. Data Management Strategy**

- **Local Persistence:** **SwiftData** using the `@Model` macro for `DailyLog` and `FoodEntry` entities.
- **Cloud Synchronization:** **iCloud with CloudKit** integration via SwiftData's `.cloudKitContainer` modifier.
