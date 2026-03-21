# ⚡ Quick Start Guide

## 🎯 3 Simple Steps to Run Your Weather App

### Step 1: Get API Key (5 minutes)
1. Go to: https://openweathermap.org/api
2. Sign up (free)
3. Copy your API key

### Step 2: Configure (1 minute)
Open `lib/core/constants/api_constants.dart` and replace:
```dart
static const String apiKey = 'YOUR_API_KEY';
```
With your actual key:
```dart
static const String apiKey = 'paste_your_key_here';
```

### Step 3: Run (2 minutes)
```bash
flutter pub get
flutter run
```

That's it! 🎉

---

## 📱 What You'll See

1. **Splash Screen** (3 seconds) - Beautiful animated intro
2. **Location Permission** - Grant access or search manually
3. **Weather Home** - Current weather for your location
4. **Forecast** - 5-day weather forecast

---

## 🎮 How to Use

### View Weather
- Home screen shows current location weather
- Pull down to refresh

### Search City
- Tap search icon (top right)
- Type city name or choose from popular cities
- View weather instantly

### Save Locations
- Search a city
- It's automatically saved
- Access via bookmark icon (top right)

### View Forecast
- Scroll down on home page
- Tap "View All" for complete forecast

---

## 🆘 Quick Troubleshooting

**Problem**: App shows error
- **Fix**: Check API key is configured correctly

**Problem**: Location not working
- **Fix**: Grant permission or use Search

**Problem**: "City not found"
- **Fix**: Check spelling or try another city

**Problem**: Dependencies not installed
- **Fix**: Run `flutter pub get`

---

## 📋 Pre-Flight Checklist

Before running:
- [ ] Flutter installed (`flutter doctor`)
- [ ] API key obtained
- [ ] API key configured in code
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Device/emulator connected

---

## 🎨 App Features

✅ Real-time weather
✅ 5-day forecast  
✅ Location-based
✅ Search cities
✅ Save favorites
✅ Offline cache
✅ Beautiful UI

---

## 📞 Need Help?

1. Check `SETUP_GUIDE.md` for detailed instructions
2. Check `API_SETUP_GUIDE.md` for API setup
3. Check `PROJECT_SUMMARY.md` for complete docs

---

**Ready? Let's Go!** 🚀

```bash
flutter pub get && flutter run
```

