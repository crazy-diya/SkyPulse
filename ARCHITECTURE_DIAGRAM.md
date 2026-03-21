# 📊 Weather App - Visual Architecture Diagram

## 🎯 Application Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SPLASH SCREEN                              │
│                    (3 seconds animation)                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                       HOME PAGE                                 │
│                 (Request Location Permission)                   │
└──────────┬────────────────────────────────────┬─────────────────┘
           │                                    │
    [GRANTED]                              [DENIED]
           │                                    │
           ▼                                    ▼
┌──────────────────────┐            ┌──────────────────────┐
│  GPS Location        │            │  Manual Search       │
│  Weather Fetch       │            │  Available           │
└──────────┬───────────┘            └──────────┬───────────┘
           │                                    │
           └────────────────┬───────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WEATHER DISPLAY                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Current Weather (Temp, Conditions, etc.)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Weather Details (Humidity, Wind, Pressure, etc.)       │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  5-Day Forecast Preview                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└────┬──────────────┬──────────────┬──────────────┬──────────────┘
     │              │              │              │
     ▼              ▼              ▼              ▼
┌─────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐
│ Search  │  │ Forecast │  │  Saved   │  │  Settings   │
│  Page   │  │ Details  │  │ Location │  │    Page     │
└─────────┘  └──────────┘  └──────────┘  └─────────────┘
```

## 🏗️ Clean Architecture Layers

```
┌───────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                           │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │      PAGES       │  │     WIDGETS      │  │      BLOC      │ │
│  │                  │  │                  │  │                │ │
│  │  • Splash        │  │  • WeatherIcon   │  │  • Events      │ │
│  │  • Home          │  │  • ForecastCard  │  │  • States      │ │
│  │  • Search        │  │  • DetailsCard   │  │  • Logic       │ │
│  │  • Forecast      │  │  • Loading       │  │                │ │
│  │  • Saved         │  │  • Error         │  │                │ │
│  │  • Settings      │  │                  │  │                │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│                                                                   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                              │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │    ENTITIES      │  │    USE CASES     │  │  REPOSITORIES  │ │
│  │                  │  │                  │  │                │ │
│  │  • Weather       │  │  • GetWeather    │  │  • Interface   │ │
│  │  • ForecastItem  │  │  • GetForecast   │  │    Only        │ │
│  │                  │  │  • GetByCoord    │  │                │ │
│  │                  │  │  • SaveLocation  │  │                │ │
│  │                  │  │  • GetSaved      │  │                │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│                                                                   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                               │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │     MODELS       │  │  DATA SOURCES    │  │  REPOSITORY    │ │
│  │                  │  │                  │  │  IMPL          │ │
│  │  • WeatherModel  │  │  • Remote (API)  │  │                │ │
│  │  • ForecastModel │  │  • Local (Cache) │  │  • Implements  │ │
│  │                  │  │                  │  │    Interface   │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│                                                                   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SOURCES                             │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐  │
│  │   OpenWeatherMap API     │  │   Local Storage (Cache)      │  │
│  │   • Current Weather      │  │   • SharedPreferences        │  │
│  │   • 5-Day Forecast       │  │   • 30-minute cache          │  │
│  └──────────────────────────┘  └──────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagram

```
   USER INTERACTION
         │
         ▼
   ┌─────────┐
   │  EVENT  │  (User taps search, requests weather, etc.)
   └────┬────┘
        │
        ▼
   ┌─────────┐
   │  BLOC   │  (Process event, apply business logic)
   └────┬────┘
        │
        ▼
   ┌──────────┐
   │ USE CASE │  (Execute specific business rule)
   └────┬─────┘
        │
        ▼
   ┌────────────┐
   │ REPOSITORY │  (Decide: API or Cache?)
   └──┬─────┬───┘
      │     │
      │     └─────────┐
      │               │
      ▼               ▼
┌──────────┐    ┌──────────┐
│  REMOTE  │    │  LOCAL   │
│   DATA   │    │   DATA   │
│  SOURCE  │    │  SOURCE  │
└────┬─────┘    └────┬─────┘
     │               │
     ▼               ▼
┌─────────┐    ┌──────────┐
│   API   │    │  CACHE   │
└────┬────┘    └────┬─────┘
     │               │
     └───────┬───────┘
             │
             ▼
        ┌────────┐
        │ MODEL  │  (Convert to entity)
        └────┬───┘
             │
             ▼
        ┌─────────┐
        │  STATE  │  (Success/Error/Loading)
        └────┬────┘
             │
             ▼
        ┌────────┐
        │   UI   │  (Update display)
        └────────┘
```

## 🎯 BLoC Pattern Flow

```
┌────────────────────────────────────────────────────────────┐
│                        BLOC PATTERN                        │
└────────────────────────────────────────────────────────────┘

USER ACTION  →  EVENT  →  BLOC  →  STATE  →  UI UPDATE

Examples:

1. Get Weather for Current Location
   ┌──────────────────────────────────────────────────┐
   │ Tap Location Button                              │
   └──────────┬───────────────────────────────────────┘
              ▼
   ┌──────────────────────────────────────────────────┐
   │ GetWeatherForCurrentLocation Event               │
   └──────────┬───────────────────────────────────────┘
              ▼
   ┌──────────────────────────────────────────────────┐
   │ WeatherBloc processes:                           │
   │  • Get GPS coordinates                           │
   │  • Call use case                                 │
   │  • Fetch from API/Cache                          │
   └──────────┬───────────────────────────────────────┘
              ▼
   ┌──────────────────────────────────────────────────┐
   │ Emit States:                                     │
   │  1. WeatherLoading                               │
   │  2. WeatherLoaded (success) OR                   │
   │     WeatherError (failure)                       │
   └──────────┬───────────────────────────────────────┘
              ▼
   ┌──────────────────────────────────────────────────┐
   │ UI Updates:                                      │
   │  • Show loading shimmer                          │
   │  • Display weather data OR                       │
   │  • Show error with retry                         │
   └──────────────────────────────────────────────────┘

2. Search City Weather
   Tap Search → GetWeatherForCity Event → Bloc Process
   → WeatherLoaded State → Display Results
```

## 📱 Screen Navigation Map

```
┌─────────────────────────────────────────────────────────────┐
│                    SPLASH SCREEN (/)                        │
│                   [Auto navigate after 3s]                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     HOME PAGE (/home)                       │
│                                                             │
│  App Bar Actions:                                           │
│  ┌────────┬──────────┬──────────┐                          │
│  │ Search │ Bookmark │ Settings │                          │
│  └───┬────┴────┬─────┴─────┬────┘                          │
│      │         │           │                                │
│      ▼         ▼           ▼                                │
│  ┌───────┐ ┌─────────┐ ┌──────────┐                        │
│  │Search │ │  Saved  │ │ Settings │                        │
│  │ Page  │ │Location │ │   Page   │                        │
│  └───────┘ └─────────┘ └──────────┘                        │
│                                                             │
│  Content:                                                   │
│  • Current Weather                                          │
│  • Weather Details                                          │
│  • Forecast Preview → [View All] → Forecast Details        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🗂️ File Organization Tree

```
lib/
│
├── main.dart                          # App entry point
│
├── core/                              # Core functionality
│   ├── constants/
│   │   └── api_constants.dart         # API config
│   ├── di/
│   │   └── injection_container.dart   # GetIt DI
│   ├── error/
│   │   ├── exceptions.dart            # Exceptions
│   │   └── failures.dart              # Failures
│   ├── network/
│   │   └── network_info.dart          # Connectivity
│   ├── services/
│   │   └── location_service.dart      # GPS
│   ├── usecase/
│   │   └── usecase.dart               # Base use case
│   └── utils/
│       └── date_formatter.dart        # Date utils
│
└── features/
    └── weather/
        │
        ├── data/                      # Data layer
        │   ├── datasources/
        │   │   ├── weather_remote_data_source.dart
        │   │   └── weather_local_data_source.dart
        │   ├── models/
        │   │   ├── weather_model.dart
        │   │   └── forecast_item_model.dart
        │   └── repositories/
        │       └── weather_repository_impl.dart
        │
        ├── domain/                    # Domain layer
        │   ├── entities/
        │   │   ├── weather.dart
        │   │   └── forecast_item.dart
        │   ├── repositories/
        │   │   └── weather_repository.dart
        │   └── usecases/
        │       ├── get_current_weather.dart
        │       ├── get_weather_by_coordinates.dart
        │       ├── get_forecast.dart
        │       ├── get_saved_locations.dart
        │       └── save_location.dart
        │
        └── presentation/              # Presentation layer
            ├── bloc/
            │   ├── weather_bloc.dart
            │   ├── weather_event.dart
            │   └── weather_state.dart
            ├── pages/
            │   ├── splash_screen.dart
            │   ├── home_page.dart
            │   ├── search_page.dart
            │   ├── forecast_details_page.dart
            │   ├── saved_locations_page.dart
            │   └── settings_page.dart
            └── widgets/
                ├── weather_icon.dart
                ├── weather_details_card.dart
                ├── forecast_card.dart
                ├── loading_widget.dart
                └── error_widget.dart
```

## 🎨 UI Component Hierarchy

```
MaterialApp
│
├── Splash Screen (Route: /)
│   └── Container (Gradient Background)
│       └── Animated Icon + Text
│
└── Home Page (Route: /home)
    ├── AppBar
    │   ├── Search Icon → Search Page
    │   ├── Bookmark Icon → Saved Locations
    │   └── Menu Icon → Settings
    │
    └── Body
        ├── RefreshIndicator
        └── SingleChildScrollView
            ├── Weather Header (Gradient)
            │   ├── City Name
            │   ├── Weather Icon
            │   ├── Temperature
            │   └── Min/Max Temp
            │
            ├── Weather Details Card
            │   ├── Feels Like
            │   ├── Humidity
            │   ├── Pressure
            │   ├── Wind Speed
            │   ├── Cloudiness
            │   └── Visibility
            │
            └── Forecast Section
                ├── Section Header (+ View All)
                └── Forecast List
                    └── Forecast Cards
```

---

**Visual representation complete!**
Use this diagram to understand the app structure quickly.

