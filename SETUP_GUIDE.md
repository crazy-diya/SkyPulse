# Weather App - Complete Setup Guide

## ⚠️ IMPORTANT: Setup Instructions

Before running the app, you MUST complete the following steps:

## Step 1: Get OpenWeatherMap API Key

1. Visit https://openweathermap.org/api
2. Click "Sign Up" and create a free account
3. After logging in, go to "API keys" section
4. Copy your API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

## Step 2: Configure the API Key

1. Open the file: `lib/core/constants/api_constants.dart`
2. Find this line:
   ```dart
   static const String apiKey = 'YOUR_API_KEY';
   ```
3. Replace `YOUR_API_KEY` with your actual API key:
   ```dart
   static const String apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
   ```
4. Save the file

## Step 3: Install Dependencies

Run this command in your terminal:
```bash
flutter pub get
```

## Step 4: Run the App

```bash
# For Android/iOS
flutter run

# For specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

## Permissions Setup

### Android
Location and internet permissions are already configured in:
- `android/app/src/main/AndroidManifest.xml`

### iOS
Location permissions are already configured in:
- `ios/Runner/Info.plist`

When you first run the app, it will ask for location permission. You need to:
1. Allow location access when prompted
2. If denied, you can still search for cities manually

## Features Overview

### 1. Splash Screen
- Beautiful animated splash screen
- Shows for 3 seconds before navigating to home

### 2. Home Page (Main Screen)
- Displays current weather for your location
- Shows temperature, weather condition, humidity, wind speed, etc.
- Displays 5-day forecast preview
- Pull to refresh
- FAB button to get current location weather

### 3. Search Page
- Search weather for any city worldwide
- Shows popular cities for quick access
- Automatically saves searched cities

### 4. Forecast Details Page
- Complete 5-day weather forecast
- Hourly forecast details
- Temperature, humidity, wind speed for each time slot

### 5. Saved Locations Page
- View all your saved/searched cities
- Quick access to weather for saved locations

## App Navigation

```
Splash Screen (3 seconds)
    ↓
Home Page
    ├── Search Icon → Search Page → City Weather
    ├── Bookmark Icon → Saved Locations Page → Select City
    ├── View All Button → Forecast Details Page
    └── FAB Button → Refresh Current Location Weather
```

## Troubleshooting

### Issue 1: "Target of URI doesn't exist" errors
**Solution**: Run `flutter pub get` to install dependencies

### Issue 2: API returns 401 Unauthorized
**Solution**: Check if you've properly configured your API key in `api_constants.dart`

### Issue 3: Location permission denied
**Solution**: 
- Go to device Settings → Apps → Weather App → Permissions → Location → Allow
- Or use the Search feature to manually enter a city name

### Issue 4: "City not found" error
**Solution**: Check the spelling of the city name or try another city

### Issue 5: No data showing
**Solution**: 
- Check your internet connection
- Verify your API key is valid
- Make sure you've run `flutter pub get`

## Testing Without Location Permission

If you don't want to grant location permission, you can still use the app:
1. Skip the location permission dialog
2. Click the search icon in the app bar
3. Search for any city manually
4. Weather will be displayed for that city

## API Rate Limits

The free OpenWeatherMap API has these limits:
- 60 calls per minute
- 1,000,000 calls per month

The app implements caching (30 minutes) to minimize API calls.

## Development Commands

```bash
# Check Flutter installation
flutter doctor

# Install dependencies
flutter pub get

# Clean build files
flutter clean

# Run the app
flutter run

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release

# Run tests
flutter test
```

## Project Structure Summary

```
lib/
├── main.dart                    # App entry point
├── core/                        # Core functionality
│   ├── constants/               # API constants
│   ├── di/                      # Dependency injection
│   ├── error/                   # Error handling
│   ├── network/                 # Network utilities
│   ├── services/                # Services (location, etc.)
│   └── utils/                   # Utility functions
└── features/
    └── weather/
        ├── data/                # Data layer (API, Cache, Models)
        ├── domain/              # Business logic (Entities, Use Cases)
        └── presentation/        # UI layer (Pages, Widgets, BLoC)
```

## Architecture Benefits

### Clean Architecture
- Separation of concerns
- Easy to test
- Independent of frameworks
- Maintainable and scalable

### BLoC Pattern
- Predictable state management
- Easy to debug
- Testable business logic
- Reactive programming

## Next Steps After Setup

1. ✅ Get API key from OpenWeatherMap
2. ✅ Configure API key in `api_constants.dart`
3. ✅ Run `flutter pub get`
4. ✅ Run `flutter run`
5. ✅ Grant location permission when prompted
6. ✅ Enjoy the weather app!

## Need Help?

If you encounter any issues:
1. Check the Troubleshooting section above
2. Make sure all setup steps are completed
3. Verify Flutter is properly installed (`flutter doctor`)
4. Check that your API key is valid

## API Documentation

OpenWeatherMap API Documentation:
- Current Weather: https://openweathermap.org/current
- 5 Day Forecast: https://openweathermap.org/forecast5

## Congratulations! 🎉

You now have a fully functional weather app with:
- ✅ Clean Architecture
- ✅ BLoC State Management
- ✅ Real-time weather data
- ✅ 5-day forecast
- ✅ Location services
- ✅ Offline caching
- ✅ Beautiful UI

Happy coding! 🚀

