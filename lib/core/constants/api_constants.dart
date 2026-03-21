class ApiConstants {
  // OpenWeatherMap API
  static const String apiKey = 'c48cc178df6fe970fbe9d5fd1d9e697c'; // Replace with your API key
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Endpoints
  static const String currentWeatherEndpoint = '/weather';
  static const String forecastEndpoint = '/forecast';
  static const String oneCallEndpoint = '/onecall';

  // Icon URL
  static String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@4x.png';
  }

  // Cache duration
  static const int cacheDurationMinutes = 30;
}

