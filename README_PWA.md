# Exercise Tracker PWA

A Progressive Web App version of Exercise Tracker that works offline and can be installed on your phone without the App Store.

## Setup & Run

### 1. Build the web app
```bash
cd exercise_tracker_pwa
flutter pub get
flutter create . --platforms=web
flutter build web --release
```

### 2. Test locally
```bash
# Install a simple server (one time)
npm install -g serve

# Run the app
serve build/web -l 5000
```

Open http://localhost:5000 in your browser.

### 3. Install on iPhone

1. Open Safari on your iPhone
2. Go to your hosted URL (see hosting options below)
3. Tap the **Share** button (square with arrow)
4. Tap **"Add to Home Screen"**
5. Tap **"Add"**

The app icon will appear on your home screen!

## Free Hosting Options

### Option A: GitHub Pages (Recommended)
1. Create a GitHub repository
2. Push the `build/web` folder contents
3. Enable GitHub Pages in repo settings
4. Your app will be at: `https://yourusername.github.io/repo-name`

### Option B: Vercel
```bash
npm install -g vercel
cd build/web
vercel
```

### Option C: Netlify
1. Go to netlify.com
2. Drag & drop the `build/web` folder
3. Get your free URL

## Data Storage

- **Offline:** Data stored in browser's IndexedDB (persists locally)
- **Limit:** ~50MB+ (plenty for exercise data)
- **Future:** Ready for Firebase cloud sync

## Features

- ✅ Works offline
- ✅ Installable on home screen
- ✅ No App Store fees
- ✅ No 7-day expiration
- ✅ Automatic updates when online
- ✅ Same features as native app

## Limitations on iOS

- Must install via Safari (not Chrome)
- No push notifications (iOS limitation)
- Data tied to browser (clearing Safari data = app data lost)

## Future: Cloud Sync

The app is ready for Firebase integration. To add cloud sync later:
1. Create Firebase project
2. Add firebase_core and cloud_firestore packages
3. Implement sync logic in database_service.dart

## Troubleshooting

**App won't install on iPhone:**
- Make sure you're using Safari
- Make sure the site is HTTPS (required for PWA)

**Data disappeared:**
- Check if Safari data was cleared
- Future cloud sync will prevent this

**App not updating:**
- Close and reopen the app
- Or clear browser cache for the site
