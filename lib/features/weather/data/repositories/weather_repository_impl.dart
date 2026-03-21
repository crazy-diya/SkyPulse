import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/forecast_item.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_local_data_source.dart';
import '../datasources/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;
  final WeatherLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  WeatherRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Weather>> getCurrentWeather(String cityName) async {
    if (await networkInfo.isConnected) {
      try {
        final weather = await remoteDataSource.getCurrentWeather(cityName);
        await localDataSource.cacheWeather(weather);
        await localDataSource.setLastCacheTime(DateTime.now());
        return Right(weather);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedWeather = await localDataSource.getLastWeather();
        return Right(cachedWeather);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Weather>> getCurrentWeatherByCoordinates(
      double lat, double lon) async {
    if (await networkInfo.isConnected) {
      try {
        final weather = await remoteDataSource.getCurrentWeatherByCoordinates(lat, lon);

        // Check if cache is still valid
        final lastCacheTime = await localDataSource.getLastCacheTime();
        final now = DateTime.now();
        final shouldCache = lastCacheTime == null ||
            now.difference(lastCacheTime).inMinutes > ApiConstants.cacheDurationMinutes;

        if (shouldCache) {
          await localDataSource.cacheWeather(weather);
          await localDataSource.setLastCacheTime(now);
        }

        return Right(weather);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedWeather = await localDataSource.getLastWeather();
        return Right(cachedWeather);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<ForecastItem>>> getForecast(String cityName) async {
    if (await networkInfo.isConnected) {
      try {
        final forecast = await remoteDataSource.getForecast(cityName);
        await localDataSource.cacheForecast(forecast);
        return Right(forecast);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedForecast = await localDataSource.getLastForecast();
        return Right(cachedForecast);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<ForecastItem>>> getForecastByCoordinates(
      double lat, double lon) async {
    if (await networkInfo.isConnected) {
      try {
        final forecast = await remoteDataSource.getForecastByCoordinates(lat, lon);
        await localDataSource.cacheForecast(forecast);
        return Right(forecast);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedForecast = await localDataSource.getLastForecast();
        return Right(cachedForecast);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSavedLocations() async {
    try {
      final locations = await localDataSource.getSavedLocations();
      return Right(locations);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveLocation(String cityName) async {
    try {
      await localDataSource.saveLocation(cityName);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeLocation(String cityName) async {
    try {
      await localDataSource.removeLocation(cityName);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}

