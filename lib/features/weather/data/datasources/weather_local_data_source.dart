import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/weather_model.dart';
import '../models/forecast_item_model.dart';

abstract class WeatherLocalDataSource {
  Future<WeatherModel> getLastWeather();
  Future<void> cacheWeather(WeatherModel weatherModel);
  Future<List<ForecastItemModel>> getLastForecast();
  Future<void> cacheForecast(List<ForecastItemModel> forecast);
  Future<List<String>> getSavedLocations();
  Future<void> saveLocation(String cityName);
  Future<void> removeLocation(String cityName);
  Future<DateTime?> getLastCacheTime();
  Future<void> setLastCacheTime(DateTime dateTime);
}

const String CACHED_WEATHER = 'CACHED_WEATHER';
const String CACHED_FORECAST = 'CACHED_FORECAST';
const String SAVED_LOCATIONS = 'SAVED_LOCATIONS';
const String LAST_CACHE_TIME = 'LAST_CACHE_TIME';

class WeatherLocalDataSourceImpl implements WeatherLocalDataSource {
  final SharedPreferences sharedPreferences;

  WeatherLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<WeatherModel> getLastWeather() async {
    final jsonString = sharedPreferences.getString(CACHED_WEATHER);
    if (jsonString != null) {
      return WeatherModel.fromJson(json.decode(jsonString));
    } else {
      throw CacheException('No cached weather data');
    }
  }

  @override
  Future<void> cacheWeather(WeatherModel weatherModel) async {
    await sharedPreferences.setString(
      CACHED_WEATHER,
      json.encode(weatherModel.toJson()),
    );
  }

  @override
  Future<List<ForecastItemModel>> getLastForecast() async {
    final jsonString = sharedPreferences.getString(CACHED_FORECAST);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => ForecastItemModel.fromJson(item)).toList();
    } else {
      throw CacheException('No cached forecast data');
    }
  }

  @override
  Future<void> cacheForecast(List<ForecastItemModel> forecast) async {
    final jsonList = forecast.map((item) => item.toJson()).toList();
    await sharedPreferences.setString(
      CACHED_FORECAST,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<String>> getSavedLocations() async {
    final locations = sharedPreferences.getStringList(SAVED_LOCATIONS);
    return locations ?? [];
  }

  @override
  Future<void> saveLocation(String cityName) async {
    final locations = await getSavedLocations();
    if (!locations.contains(cityName)) {
      locations.add(cityName);
      await sharedPreferences.setStringList(SAVED_LOCATIONS, locations);
    }
  }

  @override
  Future<void> removeLocation(String cityName) async {
    final locations = await getSavedLocations();
    locations.remove(cityName);
    await sharedPreferences.setStringList(SAVED_LOCATIONS, locations);
  }

  @override
  Future<DateTime?> getLastCacheTime() async {
    final timeString = sharedPreferences.getString(LAST_CACHE_TIME);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  @override
  Future<void> setLastCacheTime(DateTime dateTime) async {
    await sharedPreferences.setString(
      LAST_CACHE_TIME,
      dateTime.toIso8601String(),
    );
  }
}

