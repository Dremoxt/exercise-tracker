# CLAUDE.md - AI Assistant Guide for Exercise Tracker

## Project Overview

**Exercise Tracker** (branded as "Move Now") is a Flutter PWA for tracking daily exercise goals by body part categories. The app supports local-only mode (QA) and cloud-synced mode (production) with Firebase integration.

### Key Features
- 8 customizable body part categories (Chest, Back, Shoulders, Biceps, Triceps, Legs, Abs, Cardio)
- Daily set tracking with tap-to-add, long-press-to-adjust interaction
- Weekday-specific goals (configurable rest days)
- Calendar history view with color-coded achievement levels
- Monthly/weekly statistics and personal best tracking
- Google Sign-In with Firestore cloud sync (production only)
- Dark mode support
- PWA with offline capability

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.27+ (Dart 3.0+) |
| State Management | Provider |
| Local Storage | Hive (encrypted in production) |
| Cloud Backend | Firebase (Auth + Firestore) |
| Deployment | GitHub Pages (via GitHub Actions) |

## Project Structure

```
exercise-tracker/
├── lib/
│   ├── main.dart                    # App entry point, navigation
│   ├── config/
│   │   ├── environment.dart         # QA/Production environment config
│   │   ├── firebase_config.dart     # Firebase options from dart-define
│   │   └── theme.dart               # Light/dark themes, colors, icons
│   ├── models/
│   │   ├── models.dart              # Data models with Hive annotations
│   │   └── models.g.dart            # Generated Hive adapters
│   ├── providers/
│   │   └── exercise_provider.dart   # Main state provider (ChangeNotifier)
│   ├── screens/
│   │   ├── home_screen.dart         # Main tracking screen
│   │   ├── history_screen.dart      # Calendar view
│   │   ├── stats_screen.dart        # Records/statistics view
│   │   └── settings_screen.dart     # App settings
│   ├── services/
│   │   ├── database_service.dart    # Hive local storage operations
│   │   ├── cloud_sync_service.dart  # Firestore sync operations
│   │   ├── auth_service.dart        # Google Sign-In
│   │   └── secure_logger.dart       # Debug-only logging utility
│   └── widgets/
│       ├── category_card.dart       # Exercise category card
│       ├── progress_ring.dart       # Circular progress indicator
│       └── qa_banner.dart           # QA environment indicator
├── scripts/
│   ├── build_web.sh                 # Production build script
│   └── build_qa.sh                  # QA build script (no Firebase)
├── web/                             # Web-specific assets
├── ios/                             # iOS-specific configuration
├── .github/workflows/
│   └── deploy-qa.yml                # GitHub Actions deployment
├── firestore.rules                  # Firestore security rules
├── pubspec.yaml                     # Dependencies
└── analysis_options.yaml            # Lint rules
```

## Environment Configuration

### Two Environments

| Environment | Firebase | Storage | Use Case |
|-------------|----------|---------|----------|
| **QA** | Disabled | Local only (unencrypted Hive) | UI testing, development |
| **Production** | Enabled | Encrypted Hive + Firestore sync | Live app |

### Environment Detection
Set via `--dart-define=ENV=qa` or `--dart-define=ENV=production` at build time.

```dart
// lib/config/environment.dart
EnvironmentConfig.isQA          // true if QA mode
EnvironmentConfig.isProduction  // true if production
EnvironmentConfig.skipFirebase  // true in QA (skips Firebase init)
EnvironmentConfig.appName       // "Move Now" or "Move Now (QA)"
```

## Build Commands

### QA Build (No Firebase Required)
```bash
./scripts/build_qa.sh
# Or manually:
flutter build web --release --dart-define=ENV=qa
```

### Production Build
```bash
source .env && ./scripts/build_web.sh
# Or manually with all dart-defines:
flutter build web --release \
  --dart-define=ENV=production \
  --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
  --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
  --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
  --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
  --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID \
  --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID
```

### Local Development
```bash
flutter pub get
flutter run -d chrome --dart-define=ENV=qa
```

### Code Generation (Hive Adapters)
After modifying models with `@HiveType` annotations:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Data Models

### Core Models (lib/models/models.dart)

| Model | Hive TypeId | Purpose |
|-------|-------------|---------|
| `ExerciseCategory` | 0 | Body part category (id, name, icon, order) |
| `CategoryProgress` | 1 | Strokes completed for one category on a day |
| `DailyRecord` | 2 | Full day's exercise record |
| `AppSettings` | 3 | User settings (dark mode, reps, etc.) |
| `WeekdayGoals` | 4 | Per-weekday target configuration |

### Key Data Relationships
- `DailyRecord.id` is formatted as `yyyy-MM-dd`
- `DailyRecord.categoryProgress` contains a list of `CategoryProgress` per category
- `WeekdayGoals.weekdaySets` maps weekday (1=Mon, 7=Sun) to target sets

## State Management

### ExerciseProvider (lib/providers/exercise_provider.dart)

Main state holder using `ChangeNotifier`. Key patterns:

```dart
// Accessing state
final provider = Provider.of<ExerciseProvider>(context);
provider.categories       // List<ExerciseCategory>
provider.todayRecord      // DailyRecord?
provider.selectedDate     // Currently viewed date
provider.isSignedIn       // Google auth status

// Modifying state
provider.addStroke(categoryId);      // Increment strokes
provider.setStrokes(categoryId, n);  // Set specific value
provider.selectDate(date);           // Change viewed date
provider.toggleDarkMode();           // Toggle theme
```

### State Initialization Flow
1. `main()` initializes Firebase (production only)
2. `ExerciseProvider.initialize()` sets up services
3. `DatabaseService.initialize()` opens Hive boxes with encryption (production)
4. Default categories/settings created on first launch

## Services Architecture

### DatabaseService (lib/services/database_service.dart)
- Manages all Hive local storage operations
- Uses different box names for QA vs production (`_qa` suffix)
- Handles encryption in production mode
- Provides CRUD for categories, records, settings

### CloudSyncService (lib/services/cloud_sync_service.dart)
- Firestore sync operations (only active in production)
- Real-time listeners for cross-device sync
- Converts between Hive models and Firestore documents

### AuthService (lib/services/auth_service.dart)
- Google Sign-In wrapper
- Only initialized in production mode

## UI Patterns

### Navigation
Bottom navigation with 4 tabs:
1. **Today** - Main tracking screen
2. **History** - Calendar view
3. **Records** - Statistics
4. **Settings** - App configuration

### Theme System (lib/config/theme.dart)
- Navy blue primary (`#1E3A5F`)
- Green accent for completion (`#10B981`)
- 5-tier progress colors: Red → Orange → Amber → Yellow → Green
- Material 3 design system

### Progress Color Mapping
```dart
>=100% → Green (#22C55E)
>=75%  → Yellow (#EAB308)
>=51%  → Amber (#F59E0B)
>=26%  → Orange (#F97316)
<26%   → Red (#EF4444)
```

## Security Considerations

### Never Commit
- `.env`, `.env.qa`, `.env.prod` files
- `firebase_options.dart`
- `google-services.json` / `GoogleService-Info.plist`
- Any file containing API keys or secrets

### Firestore Rules
User data is scoped to authenticated user's UID:
```
/users/{userId}/daily_records/{date}
/users/{userId}/categories/{categoryId}
/users/{userId}/settings
```

### Encryption
- Production Hive boxes use AES-256 encryption
- Encryption key stored in separate Hive box
- QA mode uses unencrypted boxes for easier debugging

## Common Development Tasks

### Adding a New Category Field
1. Update `ExerciseCategory` in `lib/models/models.dart`
2. Add `@HiveField(n)` annotation with next available index
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
4. Update UI in relevant screens

### Modifying Default Categories
Edit `_initializeDefaultData()` in `lib/services/database_service.dart`

### Adding a New Screen
1. Create screen in `lib/screens/`
2. Add to navigation in `lib/main.dart` (`MainNavigationScreen`)
3. Add navigation destination icon/label

### Changing Theme Colors
Modify constants in `lib/config/theme.dart`:
- `primaryColor`, `secondaryColor`, `accentColor`
- Update `getProgressColor()` for progress thresholds

## Linting Rules

From `analysis_options.yaml`:
- `prefer_const_constructors` - Use const where possible
- `prefer_const_literals_to_create_immutables` - Const for immutable collections
- `avoid_print` - Use `SecureLogger` instead
- `prefer_single_quotes` - Single quotes for strings

## Deployment

### GitHub Pages (via GitHub Actions)
The `deploy-qa.yml` workflow:
1. Triggers on push to `main` or manual dispatch
2. Builds production web with Firebase secrets from GitHub Secrets
3. Sets up landing page (landing.html → index.html, app.html)
4. Deploys to GitHub Pages

### Required GitHub Secrets
- `PROD_FIREBASE_API_KEY`
- `PROD_FIREBASE_AUTH_DOMAIN`
- `PROD_FIREBASE_PROJECT_ID`
- `PROD_FIREBASE_STORAGE_BUCKET`
- `PROD_FIREBASE_MESSAGING_SENDER_ID`
- `PROD_FIREBASE_APP_ID`

## Testing Locally

### QA Mode (Recommended for Development)
```bash
flutter run -d chrome --dart-define=ENV=qa
```

### Production Mode (Requires Firebase Setup)
```bash
source .env
flutter run -d chrome \
  --dart-define=ENV=production \
  --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
  # ... other dart-defines
```

### Serving Built Web App
```bash
cd build/web && python3 -m http.server 8080
# Open http://localhost:8080
```

## Troubleshooting

### "Firebase is not configured" Error
- Ensure all `FIREBASE_*` environment variables are set
- Check `.env` file exists and is sourced
- For QA mode, verify `--dart-define=ENV=qa` is set

### Hive Type Adapter Errors
Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Failures
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..  # iOS only
flutter run
```

### Different Data Between QA/Production
QA uses separate Hive boxes (`*_qa` suffix) to prevent data conflicts.
