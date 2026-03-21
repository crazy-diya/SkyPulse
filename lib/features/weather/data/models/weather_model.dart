import '../../domain/entities/weather.dart';

class WeatherModel extends Weather {
  const WeatherModel({
    required super.cityName,
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
    required super.dateTime,
    super.rain,
    required super.visibility,
    required super.sunrise,
    required super.sunset,
    super.lat = 0.0,
    super.lon = 0.0,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
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
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      rain: json['rain'] != null ? (json['rain']['1h'] as num?)?.toInt() : null,
      visibility: json['visibility'] as int,
      sunrise: DateTime.fromMillisecondsSinceEpoch(json['sys']['sunrise'] * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(json['sys']['sunset'] * 1000),
      lat: (json['coord']?['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['coord']?['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
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
      'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
      'rain': rain != null ? {'1h': rain} : null,
      'visibility': visibility,
      'sys': {
        'sunrise': sunrise.millisecondsSinceEpoch ~/ 1000,
        'sunset': sunset.millisecondsSinceEpoch ~/ 1000,
      },
    };
  }
}

