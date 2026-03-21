import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String weatherCondition;
  final double size;

  const WeatherIcon({
    super.key,
    required this.weatherCondition,
    this.size = 100,
  });

  IconData _getWeatherIcon() {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.water_drop;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getWeatherColor() {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'clouds':
        return Colors.grey;
      case 'rain':
      case 'drizzle':
        return Colors.blue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'snow':
        return Colors.lightBlueAccent;
      case 'mist':
      case 'fog':
      case 'haze':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getWeatherIcon(),
      size: size,
      color: _getWeatherColor(),
    );
  }
}

