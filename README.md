# Lolapp 🐱

A personal iOS application for tracking my cat's asthma symptoms, medication administration, and daily care routines. Built with SwiftUI and CloudKit for seamless synchronization across devices.

## Overview

This is a personal app I built to manage my cat's asthma care. It provides a simple, intuitive interface to track daily symptoms, medication schedules, food intake, and care notes. All data syncs automatically across my devices via iCloud.

## Features

### 📅 Calendar Dashboard
- **Monthly calendar view** with visual health indicators
- **Quick cough tracking** - tap the + button to instantly log a cough for today
- **Color-coded cells** show cough frequency at a glance
- **Medication indicators** highlight scheduled treatment days

### 📝 Daily Detail Tracking
- **Cough monitoring** with increment/decrement controls
- **Medication management** for both prednisone and asthma medications
  - Flexible dosage and frequency settings
  - Administration tracking with checkboxes
  - Support for once or twice daily schedules
- **Nutrition tracking** with detailed soft food logging
  - Set daily intake targets (default: 300g)
  - Log individual feeding sessions with timestamps
  - View progress toward daily goals
- **Daily notes** for observations and special circumstances

### ☁️ Cloud Synchronization
- **Automatic iCloud sync** keeps data current across all devices
- **Offline support** - works without internet connection
- **Conflict resolution** ensures data integrity across devices

### 🎯 Smart Data Management
- **Automatic log creation** - logs are created only when you enter data and deleted when the data is at default state
- **Clean interface** - empty days don't clutter the calendar, can clearly visualize which days contain logs
- **Persistent tracking** - never lose important health data

## Installation

### Requirements
- iOS 17.0 or later
- iCloud account for synchronization
- Xcode 15.0+ (for development)

### Building from Source
```bash
# Clone the repository
git clone [repository-url]
cd Lolapp

# Open in Xcode
open Lolapp.xcodeproj

# Build and run
⌘ + R
```

## Usage

### How It Works
- **Calendar view** shows monthly overview with visual health indicators
- **Tap any date** to log data for that day
- **+ Button (top right):** Instantly add a cough for today
- **Track multiple aspects** of the cat's health:
   - Cough count with +/- buttons
   - Medication schedules and administration
   - Food intake with detailed logging
   - Daily observations in notes
- **Empty logs are automatically cleaned up** to keep the data tidy


## Technical Details

### Architecture
- **Framework:** SwiftUI with SwiftData for persistence
- **Cloud Sync:** CloudKit integration via SwiftData
- **Design Pattern:** MVVM with reactive data binding
- **Navigation:** SwiftUI declarative navigation

### Data Model
- **DailyLog:** Primary entity containing all daily tracking data
- **FoodEntry:** Detailed food intake records with timestamps
- **Smart defaults:** CloudKit-compatible with proper conflict resolution

### Key Files
- `LolappApp.swift` - App entry point and SwiftData configuration
- `Models/` - Data model definitions and default values  
- `Views/` - SwiftUI view implementations

## Development

### Build Commands
```bash
# Standard build
xcodebuild -project Lolapp.xcodeproj -scheme Lolapp build

# Run tests
xcodebuild -project Lolapp.xcodeproj -scheme Lolapp -destination 'platform=iOS Simulator,name=iPhone 15' test

# Create archive
xcodebuild -project Lolapp.xcodeproj -scheme Lolapp archive
```

### Project Structure
```
Lolapp/
├── Models/           # SwiftData models and defaults
├── Views/            # SwiftUI views and components
├── Assets.xcassets/  # App icons and resources
├── Info.plist       # App configuration
└── Lolapp.entitlements  # CloudKit permissions
```

### CloudKit Configuration
- Container: `iCloud.com.ephcrat.Lolapp`
- Background sync enabled for real-time updates
- Conflict resolution via `lastModified` timestamps

## Note

This is a personal app created specifically for my cat's care routine. While the code is open source and you're welcome to fork and modify it for your own needs, the app is designed around my specific use case and may not work perfectly for other pets or care scenarios without modification.

## Privacy

All data is stored locally on the device and synced via iCloud. No data is shared with third parties or stored on external servers beyond Apple's iCloud infrastructure.
