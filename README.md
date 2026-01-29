# Exercise Tracker

A Flutter iOS application for tracking daily exercise goals by body part categories.

## Features

- **8 Body Part Categories**: Chest, Back, Shoulders, Biceps, Triceps, Legs, Abs, Cardio (customizable)
- **Daily Tracking**: Tap to add sets, long-press to adjust
- **Progress Visualization**: Real-time percentage and visual indicators
- **Calendar View**: Monthly history with color-coded achievement levels
- **Records**: Monthly averages and personal best tracking
- **Customizable**: Adjust categories, target sets, and reps
- **Dark Mode**: Full dark theme support

## How It Works

1. **Daily Goal**: Complete 4 sets for each of 8 categories (32 total sets = 100%)
2. **Track Progress**: Tap a category card to add a completed set
3. **View History**: Check your calendar to see daily and monthly progress
4. **Beat Records**: Track your monthly averages and personal best

## Setup Instructions

### Prerequisites

1. **Install Flutter**: Follow the official guide at [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
   
   For macOS with Apple Silicon (M1):
   ```bash
   # Download Flutter SDK
   cd ~/development
   git clone https://github.com/flutter/flutter.git -b stable
   
   # Add to PATH (add this to ~/.zshrc)
   export PATH="$PATH:$HOME/development/flutter/bin"
   
   # Verify installation
   flutter doctor
   ```

2. **Install Xcode** (for iOS development):
   - Download from Mac App Store
   - Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   - Run: `sudo xcodebuild -runFirstLaunch`
   - Accept license: `sudo xcodebuild -license accept`

3. **Install CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```

### Project Setup

1. **Extract the project** to your desired location

2. **Navigate to project directory**:
   ```bash
   cd exercise_tracker
   ```

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **iOS Setup**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

5. **Run on iOS Simulator**:
   ```bash
   # List available simulators
   flutter devices
   
   # Run on iPhone simulator
   flutter run
   ```

6. **Run on physical device**:
   - Connect your iPhone via USB
   - Trust the computer on your device
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your device and team for signing
   - Run from Xcode or use `flutter run`

## Project Structure

```
exercise_tracker/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   └── theme.dart            # Theme configuration
│   ├── models/
│   │   ├── models.dart           # Data models
│   │   └── models.g.dart         # Hive adapters
│   ├── providers/
│   │   └── exercise_provider.dart # State management
│   ├── screens/
│   │   ├── home_screen.dart      # Main tracking screen
│   │   ├── history_screen.dart   # Calendar view
│   │   ├── stats_screen.dart     # Records view
│   │   └── settings_screen.dart  # Settings
│   ├── services/
│   │   └── database_service.dart # Local storage
│   └── widgets/
│       ├── category_card.dart    # Exercise category card
│       └── progress_ring.dart    # Circular progress indicator
├── ios/                          # iOS-specific files
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

## Customization

### Changing Default Categories

Edit `lib/services/database_service.dart` in the `_initializeDefaultData()` method.

### Changing Default Target Sets

Edit `lib/models/models.dart` in the `AppSettings` class:
```dart
AppSettings({
  this.targetSetsPerCategory = 4,  // Change this value
  this.repsPerSet = 25,            // Reference only
  ...
});
```

## Future Enhancements (Cloud Sync)

The app is designed to easily add cloud sync. The `DatabaseService` class can be extended or replaced with a cloud-based implementation. Key considerations:

1. Add Firebase or another backend
2. Implement authentication
3. Sync `DailyRecord` objects to cloud
4. Handle offline/online sync conflicts

## Troubleshooting

### "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd ios && pod install && cd ..
```

### "No devices found"
```bash
# Open iOS Simulator
open -a Simulator

# Or check connected devices
flutter devices
```

### Build errors
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## License

MIT License - Feel free to use and modify for personal use.
