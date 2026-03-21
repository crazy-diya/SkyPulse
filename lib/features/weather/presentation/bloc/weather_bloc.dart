import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/forecast_item.dart';
import '../../domain/entities/weather.dart';
import '../../domain/usecases/get_current_weather.dart';
import '../../domain/usecases/get_forecast.dart';
import '../../domain/usecases/get_saved_locations.dart';
import '../../domain/usecases/get_weather_by_coordinates.dart';
import '../../domain/usecases/save_location.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final GetCurrentWeather getCurrentWeather;
  final GetWeatherByCoordinates getWeatherByCoordinates;
  final GetForecast getForecast;
  final GetSavedLocations getSavedLocations;
  final SaveLocation saveLocation;
  final LocationService locationService;

  Weather? _currentWeather;
  List<ForecastItem> _currentForecast = [];

  WeatherBloc({
    required this.getCurrentWeather,
    required this.getWeatherByCoordinates,
    required this.getForecast,
    required this.getSavedLocations,
    required this.saveLocation,
    required this.locationService,
  }) : super(WeatherInitial()) {
    on<GetWeatherForCity>(_onGetWeatherForCity);
    on<GetWeatherForCurrentLocation>(_onGetWeatherForCurrentLocation);
    on<GetForecastForCity>(_onGetForecastForCity);
    on<GetForecastForCurrentLocation>(_onGetForecastForCurrentLocation);
    on<LoadSavedLocations>(_onLoadSavedLocations);
    on<SaveLocationEvent>(_onSaveLocation);
    on<RefreshWeather>(_onRefreshWeather);
  }

  Future<void> _onGetWeatherForCity(
    GetWeatherForCity event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading());

    final weatherResult = await getCurrentWeather(
      GetCurrentWeatherParams(cityName: event.cityName),
    );

    await weatherResult.fold(
      (failure) async {
        emit(WeatherError(failure.message));
      },
      (weather) async {
        _currentWeather = weather;

        final forecastResult = await getForecast(
          GetForecastParams(cityName: event.cityName),
        );

        forecastResult.fold(
          (failure) {
            emit(WeatherLoaded(weather: weather, forecast: []));
          },
          (forecast) {
            _currentForecast = forecast;
            emit(WeatherLoaded(weather: weather, forecast: forecast));
          },
        );
      },
    );
  }

  Future<void> _onGetWeatherForCurrentLocation(
    GetWeatherForCurrentLocation event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading());

    try {
      final position = await locationService.getCurrentLocation();

      final weatherResult = await getWeatherByCoordinates(
        GetWeatherByCoordinatesParams(
          lat: position.latitude,
          lon: position.longitude,
        ),
      );

      await weatherResult.fold(
        (failure) async {
          emit(WeatherError(failure.message));
        },
        (weather) async {
          _currentWeather = weather;

          final forecastResult = await getForecast(
            GetForecastParams(
              lat: position.latitude,
              lon: position.longitude,
            ),
          );

          forecastResult.fold(
            (failure) {
              emit(WeatherLoaded(weather: weather, forecast: []));
            },
            (forecast) {
              _currentForecast = forecast;
              emit(WeatherLoaded(weather: weather, forecast: forecast));
            },
          );
        },
      );
    } catch (e) {
      emit(LocationPermissionRequired(e.toString()));
    }
  }

  Future<void> _onGetForecastForCity(
    GetForecastForCity event,
    Emitter<WeatherState> emit,
  ) async {
    if (_currentWeather != null) {
      emit(WeatherLoading());

      final forecastResult = await getForecast(
        GetForecastParams(cityName: event.cityName),
      );

      forecastResult.fold(
        (failure) {
          emit(WeatherError(failure.message));
        },
        (forecast) {
          _currentForecast = forecast;
          emit(WeatherLoaded(weather: _currentWeather!, forecast: forecast));
        },
      );
    }
  }

  Future<void> _onGetForecastForCurrentLocation(
    GetForecastForCurrentLocation event,
    Emitter<WeatherState> emit,
  ) async {
    if (_currentWeather != null) {
      emit(WeatherLoading());

      try {
        final position = await locationService.getCurrentLocation();

        final forecastResult = await getForecast(
          GetForecastParams(
            lat: position.latitude,
            lon: position.longitude,
          ),
        );

        forecastResult.fold(
          (failure) {
            emit(WeatherError(failure.message));
          },
          (forecast) {
            _currentForecast = forecast;
            emit(WeatherLoaded(weather: _currentWeather!, forecast: forecast));
          },
        );
      } catch (e) {
        emit(LocationPermissionRequired(e.toString()));
      }
    }
  }

  Future<void> _onLoadSavedLocations(
    LoadSavedLocations event,
    Emitter<WeatherState> emit,
  ) async {
    final result = await getSavedLocations(const NoParams());

    result.fold(
      (failure) {
        emit(WeatherError(failure.message));
      },
      (locations) {
        emit(SavedLocationsLoaded(locations));
      },
    );
  }

  Future<void> _onSaveLocation(
    SaveLocationEvent event,
    Emitter<WeatherState> emit,
  ) async {
    await saveLocation(SaveLocationParams(cityName: event.cityName));
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    if (_currentWeather != null) {
      emit(WeatherLoading());
      emit(WeatherLoaded(
        weather: _currentWeather!,
        forecast: _currentForecast,
      ));
    }
  }
}

