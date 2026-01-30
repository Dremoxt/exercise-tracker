# CLAUDE.md - AI Assistant Guide for Exercise Tracker

This document provides comprehensive guidance for AI assistants working with this codebase.

## Project Overview

**Exercise Tracker (Move Now)** is a cross-platform fitness tracking application built with Flutter. It allows users to track daily exercise goals across customizable body part categories, view historical data, and optionally sync across devices via Firebase.

- **Current Version:** 1.0.0+1
- **App Name:** Move Now (QA variant: "Move Now (QA)")
- **Platforms:** Web (PWA), iOS, Android
- **Framework:** Flutter 3.27.0 / Dart 3.0+

## Directory Structure

```
/home/user/exercise-tracker/
├── lib/                           # Main Dart source code
│   ├── main.dart                  # App entry point with navigation setup
│   ├── config/                    # Configuration management
│   │   ├── theme.dart            # Material Design 3 theme (light/dark)
│   │   ├── environment.dart       # Environment-specific settings
│   │   └── firebase_config.dart   # Firebase initialization & credentials
│   ├── models/                    # Data models with Hive persistence
│   │   ├── models.dart            # Core data structures
│   │   └── models.g.dart          # Generated Hive adapters (DO NOT EDIT)
│   ├── providers/                 # State management (Provider pattern)
│   │   └── exercise_provider.dart # Main app state management
│   ├── services/                  # Business logic and data access
│   │   ├── database_service.dart  # Hive local storage with encryption
│   │   ├── auth_service.dart      # Firebase authentication
│   │   ├── cloud_sync_service.dart# Real-time cloud synchronization
│   │   └── secure_logger.dart     # Debug logging utilities
│   ├── screens/                   # UI screens
│   │   ├── home_screen.dart       # Daily tracking interface
│   │   ├── history_screen.dart    # Calendar and monthly view
│   │   ├── stats_screen.dart      # Records and performance analytics
│   │   └── settings_screen.dart   # Configuration and customization
│   └── widgets/                   # Reusable UI components
│       ├── category_card.dart     # Exercise category display card
│       ├── progress_ring.dart     # Animated circular progress indicator
│       └── qa_banner.dart         # QA environment indicator banner
├── web/                           # Web platform configuration
│   ├── index.html                 # Main HTML with PWA setup and CSP headers
│   ├── manifest.json              # PWA manifest
│   └── landing.html               # Landing page
├── ios/                           # iOS native code
├── .github/workflows/             # CI/CD automation
│   └── deploy-qa.yml              # Production deployment workflow
├── scripts/                       # Build automation
│   ├── build_web.sh               # Production web build script
│   └── build_qa.sh                # QA web build script
├── pubspec.yaml                   # Flutter dependencies
├── firestore.rules                # Firebase security rules
└── analysis_options.yaml          # Dart lint configuration
```

## Key Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.27.0 | Cross-platform UI framework |
| Dart | >=3.0.0 | Programming language |
| Provider | 6.1.1 | State management |
| Hive | 2.2.3 | Local NoSQL database |
| Firebase Core | 3.9.0 | Firebase initialization |
| Cloud Firestore | 5.6.0 | Real-time cloud database |
| Firebase Auth | 5.4.0 | User authentication |
| Google Sign-In | 6.2.2 | OAuth authentication |

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (after modifying models)
flutter pub run build_runner build --delete-conflicting-outputs

# Run in debug mode
flutter run -d chrome   # Web
flutter run -d ios      # iOS simulator

# Build for production
./scripts/build_web.sh  # Requires env vars set

# Build for QA (no Firebase)
./scripts/build_qa.sh

# Run linter
flutter analyze

# Run tests
flutter test
```

## Architecture Overview

### Layered Architecture
```
Widgets (UI Components)
    ↓
Screens (Page-level UI)
    ↓
Provider (State Management)
    ↓
Services (Business Logic)
    ↓
Models (Data Structures)
```

### State Management (Provider Pattern)
- Single `ExerciseProvider` serves as app-wide state container
- Uses `ChangeNotifier` with `notifyListeners()` for reactivity
- Screens wrap content with `Consumer<ExerciseProvider>` for reactive rebuilds

### Data Flow
```
User Interaction → Screen Handler → Provider Method → DatabaseService
    → Hive Storage → notifyListeners() → Widget Rebuild → UI Update
    → (Optional) CloudSyncService → Firebase
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, navigation setup, error handling |
| `lib/providers/exercise_provider.dart` | Central state management (150+ lines) |
| `lib/services/database_service.dart` | Local storage operations (596 lines) |
| `lib/models/models.dart` | All data model definitions |
| `lib/config/environment.dart` | QA vs Production environment handling |

## Code Conventions

### Dart Style
- **Prefer `const` constructors** where possible
- **Single quotes** for strings
- **Avoid `print()` statements** - use `SecureLogger` instead
- **Null-safety** required throughout (Dart 3.0+)

### Widget Patterns
```dart
// Screens use Consumer for state access
Consumer<ExerciseProvider>(
  builder: (context, provider, child) {
    return Scaffold(...);
  }
)

// Cards use GestureDetector for interactions
GestureDetector(
  onTap: onTap,
  onLongPress: onLongPress,
  child: AnimatedContainer(...)
)
```

### Model Pattern
```dart
// Models use Hive annotations
@HiveType(typeId: 0)
class ExerciseCategory extends HiveObject {
  @HiveField(0)
  final String id;
  // ...
}
```

### Service Pattern
- Services are singleton or instantiated once
- Use async/await for asynchronous operations
- Include try-catch with logging for error handling

## Environment Configuration

The app supports two environments controlled via `--dart-define=ENV=`:

| Environment | Flag | Firebase | Local Storage |
|-------------|------|----------|---------------|
| Production | `ENV=production` | Enabled | AES Encrypted |
| QA | `ENV=qa` | Disabled | Plain |

### Required Environment Variables (Production)
```
FIREBASE_API_KEY
FIREBASE_AUTH_DOMAIN
FIREBASE_PROJECT_ID
FIREBASE_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_APP_ID
FIREBASE_MEASUREMENT_ID (optional)
```

## Data Models

| Model | Purpose |
|-------|---------|
| `ExerciseCategory` | Body part category with icon |
| `CategoryProgress` | Completed sets per category per day |
| `DailyRecord` | Daily exercise record with achievement % |
| `AppSettings` | User preferences (dark mode, target sets) |
| `WeekdayGoals` | Per-day goal configuration (rest days) |
| `CategoryMonthlyStats` | Monthly performance metrics |
| `MonthlySummary` | Monthly summary with averages |

## Important Implementation Details

### Progress Calculation
- Achievement percentage: `(completed sets / target sets) * 100`
- 5-tier color system: red (0-19%) → orange (20-39%) → amber (40-59%) → yellow (60-79%) → green (80-100%)
- Rest days (weekday goals = 0) are excluded from averages

### Hive Storage Boxes
- `categories` - Exercise category definitions
- `dailyRecords` - Historical daily records
- `settings` - App settings
- `weekdayGoals` - Per-weekday target configurations

### Cloud Sync
- Real-time Firestore listeners for bidirectional sync
- Data scoped to `users/{userId}` in Firestore
- Offline-first: local storage always works, syncs when online

## Build & Deployment

### GitHub Actions Workflow (`deploy-qa.yml`)
1. Triggered on push to `main` or manual dispatch
2. Builds Flutter web with environment variables from GitHub Secrets
3. Deploys to GitHub Pages

### Build Scripts
- `scripts/build_web.sh` - Production build (requires all env vars)
- `scripts/build_qa.sh` - QA build (no Firebase, for testing)

## Testing

**Current Status:** No test suite exists yet

**Testing Areas to Implement:**
1. Unit tests for `ExerciseProvider` state management
2. Integration tests for `DatabaseService` operations
3. Widget tests for screen layouts
4. Firebase integration tests for cloud sync

## Security Considerations

- **CSP Headers:** Configured in `web/index.html`
- **Firestore Rules:** Auth-based access control in `firestore.rules`
- **Encrypted Storage:** Production uses AES cipher for Hive
- **Sensitive Files:** Never commit `.env` files or Firebase credentials

## Common Tasks for AI Assistants

### Adding a New Screen
1. Create screen file in `lib/screens/`
2. Use `Consumer<ExerciseProvider>` for state access
3. Add navigation in `main.dart` if needed
4. Follow existing screen patterns

### Adding a New Model
1. Add model class in `lib/models/models.dart` with Hive annotations
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Register adapter in `database_service.dart` initialization
4. Add CRUD methods in `database_service.dart`

### Modifying State
1. Add methods to `ExerciseProvider`
2. Call `notifyListeners()` after state changes
3. Use in widgets via `Consumer` or `Provider.of`

### Adding a New Service
1. Create service file in `lib/services/`
2. Follow singleton or instance pattern
3. Use `SecureLogger` for debug logging
4. Add proper error handling with try-catch

## Files to Never Edit Manually

- `lib/models/models.g.dart` - Auto-generated by build_runner
- `pubspec.lock` - Managed by Flutter
- `ios/Pods/` - CocoaPods managed
- `build/` - Build output directory

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hive type adapter errors | Run `flutter pub run build_runner build --delete-conflicting-outputs` |
| Firebase init failures | Check environment variables and Firebase config |
| Web build CSP errors | Review `web/index.html` CSP headers |
| iOS pod issues | Run `cd ios && pod install --repo-update` |

## Version Control

- **Main Branch:** `main` - production-ready code
- **Feature Branches:** Create from `main`, merge via PR
- **Commits:** Use descriptive messages following conventional commits
