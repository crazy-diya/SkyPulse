import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class GetWeatherByCoordinates implements UseCase<Weather, GetWeatherByCoordinatesParams> {
  final WeatherRepository repository;

  GetWeatherByCoordinates(this.repository);

  @override
  Future<Either<Failure, Weather>> call(GetWeatherByCoordinatesParams params) async {
    return await repository.getCurrentWeatherByCoordinates(params.lat, params.lon);
  }
}

class GetWeatherByCoordinatesParams {
  final double lat;
  final double lon;

  GetWeatherByCoordinatesParams({required this.lat, required this.lon});
}

