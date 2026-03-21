import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/api_constants.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';

class CitySearchResult {
  final String name;
  final String country;
  final String state;
  final double lat;
  final double lon;

  CitySearchResult({
    required this.name,
    required this.country,
    required this.state,
    required this.lat,
    required this.lon,
  });

  factory CitySearchResult.fromJson(Map<String, dynamic> json) {
    return CitySearchResult(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      lat: json['lat']?.toDouble() ?? 0.0,
      lon: json['lon']?.toDouble() ?? 0.0,
    );
  }

  String get displayName {
    if (state.isNotEmpty) return '$name, $state, $country';
    return '$name, $country';
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  final List<String> _popularCities = [
    'London', 'New York', 'Tokyo', 'Paris', 'Sydney',
    'Dubai', 'Singapore', 'Mumbai', 'Istanbul', 'Berlin',
    'Madrid', 'Rome', 'Amsterdam', 'Bangkok', 'Hong Kong',
    'Los Angeles', 'Seoul', 'Cairo', 'Toronto', 'Colombo',
  ];

  List<CitySearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'http://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(query.trim())}&limit=10&appid=${ApiConstants.apiKey}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((j) => CitySearchResult.fromJson(j)).toList();
          _isSearching = false;
        });
      } else {
        setState(() { _searchResults = []; _isSearching = false; });
      }
    } catch (_) {
      setState(() { _searchResults = []; _isSearching = false; });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchCities(query));
  }

  void _searchWeather(BuildContext context, String cityName) {
    if (cityName.trim().isNotEmpty) {
      context.read<WeatherBloc>().add(GetWeatherForCity(cityName.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WeatherBloc>(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Search City',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: BlocListener<WeatherBloc, WeatherState>(
            listener: (context, state) {
              if (state is WeatherLoaded) {
                context.read<WeatherBloc>().add(SaveLocationEvent(state.weather.cityName));
                Navigator.pop(context, state.weather);
              } else if (state is WeatherError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red[800],
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _searchWeather(context, _searchController.text);
                      }
                    },
                  ),
                ));
              }
            },
            child: FadeTransition(
              opacity: _fade,
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Search bar ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3A5C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.search_rounded, color: Colors.white54, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Search for a city...',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 15),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                textInputAction: TextInputAction.search,
                                onChanged: (v) {
                                  setState(() {});
                                  _onSearchChanged(v);
                                },
                                onSubmitted: (v) => _searchWeather(context, v),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── Body ──────────────────────────────────
                    Expanded(
                      child: BlocBuilder<WeatherBloc, WeatherState>(
                        builder: (context, state) {
                          if (state is WeatherLoading) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
                                  SizedBox(height: 16),
                                  Text('Loading weather...', style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                            );
                          }
                          if (_searchController.text.trim().length >= 2) {
                            return _buildSearchResults(context);
                          }
                          return _buildPopularCities(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
            SizedBox(height: 16),
            Text('Searching...', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            const Text('No cities found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Try a different search term',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
          child: Text(
            '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, letterSpacing: 1),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final city = _searchResults[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 250 + index * 50),
                curve: Curves.easeOut,
                builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
                child: GestureDetector(
                  onTap: () => _searchWeather(context, city.name),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3A5C),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.location_city_rounded, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(city.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 3),
                              Text(
                                city.state.isNotEmpty ? '${city.state}, ${city.country}' : city.country,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue, size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularCities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Text(
            'POPULAR CITIES',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _popularCities.length,
            itemBuilder: (context, index) {
              final city = _popularCities[index];
              final colors = [Colors.blue, Colors.teal, Colors.purple, Colors.orange, Colors.green, Colors.indigo];
              final color = colors[index % colors.length];
              return GestureDetector(
                onTap: () => _searchWeather(context, city),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A5C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(city,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
