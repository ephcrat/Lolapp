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

    - `isAsthmaMedScheduled`: `Bool` (Is asthma med scheduled for this day? Default: false).
    - `asthmaMedDosagePuffs`: `Int?` (Optional: Number of puffs per dose. Relevant if scheduled).
    - `asthmaMedFrequency`: `Enum?` (Optional: `.onceADay`, `.twiceADay`. Relevant if scheduled).
    - `didAdministerAsthmaMedDose1`: `Bool` (Was the first/only dose given? Default: false).
    - `didAdministerAsthmaMedDose2`: `Bool?` (Optional: Was the second dose given? Relevant if scheduled for twice daily. Default: nil or false).

  - **Food Tracking:**
    - `softFoodGivenGrams`: `Int` (Total grams of soft food given today. Default: 0).
    - _(Consider adding `softFoodTargetGrams`: `Int` here if the target might change daily or needs to be synced, otherwise keep it as a UI constant or app setting)_.

**II. User Interface (UI) & User Experience (UX) Flow**

Focus on simplicity and clarity across two main views.

1.  **Main View: Calendar Dashboard**

    - **Layout:** Monthly calendar grid, navigable between months.
    - **Cells (Days):**
      - **Background:** Opacity/Color maps to `coughCount` (0 = light, 1-5+ = increasingly dark/opaque).
      - **Indicator Dot (Prednisone):** Small, high-contrast dot if `isPrednisoneScheduled` is true.
      - **Indicator Dot (Asthma Med - Optional):** Consider adding a _second_, differently colored/positioned dot if `isAsthmaMedScheduled` is true. Alternatively, keep the calendar focused only on coughs and _any_ scheduled medication (perhaps a single dot type if _either_ med is scheduled) to avoid visual clutter. _Decision: Let's start with just the prednisone dot for simplicity, as it might be the more critical/variable medication._ The detail view will show the full status.
      - **Today's Date:** Clearly highlighted.
    - **Interaction:** Tap day cell -> `Day Detail View`.
    - **Quick Action (Optional):** "+ Cough" button for today's log.

2.  **Day Detail View**
    - **Context:** Selected `date` displayed prominently.
    - **Layout:** Organized into logical sections.
    - **Sections:**
      - **Cough Tracking:**
        - Display: Current `coughCount`.
        - Controls: "+/-" buttons or stepper to modify `coughCount`.
      - **Prednisone Schedule & Status:**
        - Control: Toggle "Schedule Prednisone?". Binds to `isPrednisoneScheduled`.
        - Conditional Controls (If ON): Input for `prednisoneDosageDrops`, Picker for `prednisoneFrequency`.
      - **Asthma Medication Schedule & Status:**
        - Control: Toggle "Schedule Asthma Medication?". Binds to `isAsthmaMedScheduled`.
        - Conditional Controls (If ON): Input for `asthmaMedDosagePuffs` (e.g., "Dosage (puffs):"), Picker for `asthmaMedFrequency`.
      - **Daily Tasks / Medication Administration (Checklist):**
        - _Prednisone:_
          - Checkbox: "Administered Prednisone Dose 1". Binds to `didAdministerPrednisoneDose1`. Visible if `isPrednisoneScheduled`.
          - Checkbox: "Administered Prednisone Dose 2". Binds to `didAdministerPrednisoneDose2`. Visible if `isPrednisoneScheduled` and `prednisoneFrequency` is `.twiceADay`.
        - _Asthma Medication:_
          - Checkbox: "Administered Asthma Med Dose 1". Binds to `didAdministerAsthmaMedDose1`. Visible if `isAsthmaMedScheduled`.
          - Checkbox: "Administered Asthma Med Dose 2". Binds to `didAdministerAsthmaMedDose2`. Visible if `isAsthmaMedScheduled` and `asthmaMedFrequency` is `.twiceADay`.
      - **Soft Food Intake:**
        - Display: "Target: 300g", "Given: [X]g", "Remaining: [Y]g".
        - Input Group: Text field for grams, "Add Food" button.
        - Interaction: Adds entered grams to `softFoodGivenGrams`, updates display.
      - **Notes:**
        - Input: Multi-line `TextEditor` bound to `notes`.
    - **Interaction:** Auto-save changes via SwiftData bindings. Navigate back to Calendar.

**III. Data Management Strategy**

- **Local Persistence:** **SwiftData** using the `@Model` macro for the `DailyLog` entity. Manages local SQLite storage. Ensures full offline functionality.
- **Cloud Synchronization:** **iCloud with CloudKit** integration via SwiftData's `.cloudKitContainer` modifier. Requires iCloud capabilities enabled in Xcode and an iCloud container configured. Handles automatic background sync, backup, restore, and conflict resolution based on `lastModified`. Data is private to the user's iCloud account.
