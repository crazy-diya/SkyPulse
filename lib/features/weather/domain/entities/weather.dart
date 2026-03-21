import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final int cloudiness;
  final String description;
  final String mainCondition;
  final String icon;
  final DateTime dateTime;
  final int? rain;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;
  final double lat;
  final double lon;

  const Weather({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.cloudiness,
    required this.description,
    required this.mainCondition,
    required this.icon,
    required this.dateTime,
    this.rain,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    this.lat = 0.0,
    this.lon = 0.0,
  });

  @override
  List<Object?> get props => [
        cityName,
        temperature,
        feelsLike,
        tempMin,
        tempMax,
        humidity,
        pressure,
        windSpeed,
        cloudiness,
        description,
        mainCondition,
        icon,
        dateTime,
        rain,
        visibility,
        sunrise,
        sunset,
        lat,
        lon,
      ];
}

