import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/weather.dart';
import '../entities/forecast_item.dart';

abstract class WeatherRepository {
  Future<Either<Failure, Weather>> getCurrentWeather(String cityName);
  Future<Either<Failure, Weather>> getCurrentWeatherByCoordinates(
      double lat, double lon);
  Future<Either<Failure, List<ForecastItem>>> getForecast(String cityName);
  Future<Either<Failure, List<ForecastItem>>> getForecastByCoordinates(
      double lat, double lon);
  Future<Either<Failure, List<String>>> getSavedLocations();
  Future<Either<Failure, void>> saveLocation(String cityName);
  Future<Either<Failure, void>> removeLocation(String cityName);
}

