import 'package:flutter/material.dart';
import '../../domain/entities/weather.dart';

class WeatherDetailsCard extends StatelessWidget {
  final Weather weather;

  const WeatherDetailsCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.thermostat,
              'Feels Like',
              '${weather.feelsLike.round()}°C',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.water_drop,
              'Humidity',
              '${weather.humidity}%',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.speed,
              'Pressure',
              '${weather.pressure} hPa',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.air,
              'Wind Speed',
              '${weather.windSpeed} m/s',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.cloud,
              'Cloudiness',
              '${weather.cloudiness}%',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.visibility,
              'Visibility',
              '${(weather.visibility / 1000).toStringAsFixed(1)} km',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

