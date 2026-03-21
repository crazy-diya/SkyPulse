import 'package:equatable/equatable.dart';

class ForecastItem extends Equatable {
  final DateTime dateTime;
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
  final int? rain;
  final double? pop; // Probability of precipitation

  const ForecastItem({
    required this.dateTime,
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
    this.rain,
    this.pop,
  });

  @override
  List<Object?> get props => [
        dateTime,
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
        rain,
        pop,
      ];
}

