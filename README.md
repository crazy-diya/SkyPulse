# Weather App

A beautiful and feature-rich weather application built with Flutter, implementing Clean Architecture and BLoC for state management.

## Features

- 🌤️ **Current Weather**: Get real-time weather information for any location
- 📍 **Location Services**: Automatic weather detection based on your current location
- 📊 **5-Day Forecast**: Detailed weather forecast for the next 5 days
- 🔍 **Search**: Search weather for any city worldwide
- ⭐ **Saved Locations**: Save and quickly access your favorite locations
- 🎨 **Beautiful UI**: Modern and intuitive user interface
- 📱 **Responsive Design**: Works seamlessly on different screen sizes
- 💾 **Offline Support**: View cached weather data when offline

## Architecture

This app follows **Clean Architecture** principles with three main layers:

### 1. Presentation Layer
- **Pages**: SplashScreen, HomePage, SearchPage, ForecastDetailsPage, SavedLocationsPage
- **BLoC**: State management using flutter_bloc
- **Widgets**: Reusable UI components

### 2. Domain Layer
- **Entities**: Weather, ForecastItem
- **Use Cases**: GetCurrentWeather, GetWeatherByCoordinates, GetForecast, GetSavedLocations, SaveLocation
- **Repository Interface**: Abstract repository contract

### 3. Data Layer
- **Models**: Data models extending entities
- **Data Sources**: Remote (API) and Local (Cache)
- **Repository Implementation**: Concrete implementation of repository

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.x or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- OpenWeatherMap API key

### 2. Get OpenWeatherMap API Key
1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Generate an API key

### 3. Configure API Key
Open `lib/core/constants/api_constants.dart` and replace `YOUR_API_KEY` with your actual API key:

```dart
static const String apiKey = 'your_actual_api_key_here';
```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Run the App
```bash
flutter run
```

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: BLoC (flutter_bloc)
- **Dependency Injection**: GetIt
- **API Integration**: http
- **Local Storage**: shared_preferences
- **Location Services**: geolocator, permission_handler
- **Functional Programming**: dartz
- **UI Enhancement**: shimmer, cached_network_image, lottie

Built with ❤️ using Flutter
