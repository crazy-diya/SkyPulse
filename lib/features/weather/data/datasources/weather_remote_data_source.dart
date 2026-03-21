import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/forecast_item_model.dart';
import '../models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> getCurrentWeather(String cityName);
  Future<WeatherModel> getCurrentWeatherByCoordinates(double lat, double lon);
  Future<List<ForecastItemModel>> getForecast(String cityName);
  Future<List<ForecastItemModel>> getForecastByCoordinates(double lat, double lon);
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final http.Client client;

  WeatherRemoteDataSourceImpl({required this.client});

  @override
  Future<WeatherModel> getCurrentWeather(String cityName) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.currentWeatherEndpoint}'
      '?q=$cityName&appid=${ApiConstants.apiKey}&units=metric',
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw ServerException('City not found');
    } else {
      throw ServerException('Failed to load weather data');
    }
  }

  @override
  Future<WeatherModel> getCurrentWeatherByCoordinates(double lat, double lon) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.currentWeatherEndpoint}'
      '?lat=$lat&lon=$lon&appid=${ApiConstants.apiKey}&units=metric',
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to load weather data');
    }
  }

  @override
  Future<List<ForecastItemModel>> getForecast(String cityName) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.forecastEndpoint}'
      '?q=$cityName&appid=${ApiConstants.apiKey}&units=metric',
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> forecastList = data['list'];
      return forecastList.map((item) => ForecastItemModel.fromJson(item)).toList();
    } else if (response.statusCode == 404) {
      throw ServerException('City not found');
    } else {
      throw ServerException('Failed to load forecast data');
    }
  }

  @override
  Future<List<ForecastItemModel>> getForecastByCoordinates(double lat, double lon) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.forecastEndpoint}'
      '?lat=$lat&lon=$lon&appid=${ApiConstants.apiKey}&units=metric',
    );

    final response = await client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> forecastList = data['list'];
      return forecastList.map((item) => ForecastItemModel.fromJson(item)).toList();
    } else {
      throw ServerException('Failed to load forecast data');
    }
  }
}

