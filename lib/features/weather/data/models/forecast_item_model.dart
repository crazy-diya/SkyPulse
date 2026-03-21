import '../../domain/entities/forecast_item.dart';

class ForecastItemModel extends ForecastItem {
  const ForecastItemModel({
    required super.dateTime,
    required super.temperature,
    required super.feelsLike,
    required super.tempMin,
    required super.tempMax,
    required super.humidity,
    required super.pressure,
    required super.windSpeed,
    required super.cloudiness,
    required super.description,
    required super.mainCondition,
    required super.icon,
    super.rain,
    super.pop,
  });

  factory ForecastItemModel.fromJson(Map<String, dynamic> json) {
    return ForecastItemModel(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      pressure: json['main']['pressure'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      cloudiness: json['clouds']['all'] as int,
      description: json['weather'][0]['description'] ?? '',
      mainCondition: json['weather'][0]['main'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      rain: json['rain'] != null ? (json['rain']['3h'] as num?)?.toInt() : null,
      pop: json['pop'] != null ? (json['pop'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
      'main': {
        'temp': temperature,
        'feels_like': feelsLike,
        'temp_min': tempMin,
        'temp_max': tempMax,
        'humidity': humidity,
        'pressure': pressure,
      },
      'wind': {
        'speed': windSpeed,
      },
      'clouds': {
        'all': cloudiness,
      },
      'weather': [
        {
          'description': description,
          'main': mainCondition,
          'icon': icon,
        }
      ],
      'rain': rain != null ? {'3h': rain} : null,
      'pop': pop,
    };
  }
}

