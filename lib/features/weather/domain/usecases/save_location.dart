import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/weather_repository.dart';

class SaveLocation implements UseCase<void, SaveLocationParams> {
  final WeatherRepository repository;

  SaveLocation(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveLocationParams params) async {
    return await repository.saveLocation(params.cityName);
  }
}

class SaveLocationParams {
  final String cityName;

  SaveLocationParams({required this.cityName});
}

