import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/forecast_item.dart';
import '../repositories/weather_repository.dart';

class GetForecast implements UseCase<List<ForecastItem>, GetForecastParams> {
  final WeatherRepository repository;

  GetForecast(this.repository);

  @override
  Future<Either<Failure, List<ForecastItem>>> call(GetForecastParams params) async {
    if (params.cityName != null) {
      return await repository.getForecast(params.cityName!);
    } else if (params.lat != null && params.lon != null) {
      return await repository.getForecastByCoordinates(params.lat!, params.lon!);
    } else {
      return const Left(ServerFailure('Invalid parameters'));
    }
  }
}

class GetForecastParams {
  final String? cityName;
  final double? lat;
  final double? lon;

  GetForecastParams({this.cityName, this.lat, this.lon});
}

