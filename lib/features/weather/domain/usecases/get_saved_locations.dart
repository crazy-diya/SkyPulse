import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/weather_repository.dart';

class GetSavedLocations implements UseCase<List<String>, NoParams> {
  final WeatherRepository repository;

  GetSavedLocations(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getSavedLocations();
  }
}

