import 'package:equatable/equatable.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

class GetWeatherForCity extends WeatherEvent {
  final String cityName;

  const GetWeatherForCity(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

class GetWeatherForCurrentLocation extends WeatherEvent {
  const GetWeatherForCurrentLocation();
}

class GetForecastForCity extends WeatherEvent {
  final String cityName;

  const GetForecastForCity(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

class GetForecastForCurrentLocation extends WeatherEvent {
  const GetForecastForCurrentLocation();
}

class LoadSavedLocations extends WeatherEvent {
  const LoadSavedLocations();
}

class SaveLocationEvent extends WeatherEvent {
  final String cityName;

  const SaveLocationEvent(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

class RefreshWeather extends WeatherEvent {
  const RefreshWeather();
}

