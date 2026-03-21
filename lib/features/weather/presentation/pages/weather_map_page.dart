import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/weather.dart';
import '../../../../core/constants/api_constants.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';

class WeatherMapPage extends StatefulWidget {
  final Weather weather;
  final bool embedded;
  const WeatherMapPage({super.key, required this.weather, this.embedded = false});

  @override
  State<WeatherMapPage> createState() => _WeatherMapPageState();
}

class _WeatherMapPageState extends State<WeatherMapPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulse;
  late Animation<double> _fade;

  // ── Search bar animation ───────────────────────────────────────────────
  late AnimationController _searchBarController;
  late Animation<double> _searchBarWidth;
  late Animation<double> _searchBarOpacity;
  bool _searchBarVisible = false;
  bool _searchingCity = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_SearchSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  String _lastQuery = '';

  late MapController _mapController;
  String _selectedLayer = 'temperature';
  final List<_NearbyCity> _nearbyCities = [];
  bool _loadingNearby = false;

  // Tapped / selected pin state
  _TappedLocation? _tappedLocation;
  bool _fetchingTapped = false;

  final List<_MapLayer> _layers = [
    _MapLayer('temperature', 'Temp',     Icons.thermostat_rounded,  Colors.red,      'temp_new'),
    _MapLayer('clouds',      'Clouds',   Icons.cloud_rounded,       Colors.blueGrey, 'clouds_new'),
    _MapLayer('precipitation','Rain',    Icons.water_drop_rounded,  Colors.blue,     'precipitation_new'),
    _MapLayer('wind',        'Wind',     Icons.air_rounded,         Colors.teal,     'wind_new'),
    _MapLayer('pressure',    'Pressure', Icons.compress_rounded,    Colors.purple,   'pressure_new'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _mapController = MapController();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _pulse = Tween<double>(begin: 0.7, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _fade  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Search bar animation
    _searchBarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _searchBarWidth   = CurvedAnimation(parent: _searchBarController, curve: Curves.easeOutCubic);
    _searchBarOpacity = CurvedAnimation(parent: _searchBarController, curve: Curves.easeIn);

    _fetchNearbyCities();
  }

  double get _lat => widget.weather.lat != 0 ? widget.weather.lat : 51.5;
  double get _lon => widget.weather.lon != 0 ? widget.weather.lon : -0.12;

  // ── Fetch 6 nearby cities around current location ──────────────────────
  Future<void> _fetchNearbyCities() async {
    setState(() => _loadingNearby = true);
    final offsets = [[2.0, 2.0], [-2.0, 2.0], [2.0, -2.0], [-3.0, -1.0], [4.0, 0.0], [0.0, 4.0]];
    final cities = <_NearbyCity>[];
    for (final offset in offsets) {
      try {
        final lat = _lat + offset[0];
        final lon = _lon + offset[1];
        final data = await _fetchWeatherByLatLon(lat, lon);
        if (data != null) {
          cities.add(_NearbyCity.fromApi(data));
        }
      } catch (_) {}
    }
    if (mounted) setState(() { _nearbyCities.addAll(cities); _loadingNearby = false; });
  }

  // ── Generic weather fetch by lat/lon ──────────────────────────────────
  Future<Map<String, dynamic>?> _fetchWeatherByLatLon(double lat, double lon) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/weather?lat=$lat&lon=$lon&appid=${ApiConstants.apiKey}&units=metric',
    );
    final resp = await http.get(url);
    if (resp.statusCode == 200) return json.decode(resp.body) as Map<String, dynamic>;
    return null;
  }

  // ── Handle tap on the map canvas ──────────────────────────────────────
  Future<void> _onMapTap(TapPosition tapPos, LatLng latLng) async {
    setState(() { _fetchingTapped = true; _tappedLocation = null; });
    try {
      final data = await _fetchWeatherByLatLon(latLng.latitude, latLng.longitude);
      if (data != null && mounted) {
        final loc = _TappedLocation.fromApi(data, latLng.latitude, latLng.longitude);
        setState(() { _tappedLocation = loc; _fetchingTapped = false; });
        _showWeatherSheet(loc);
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingTapped = false);
    }
  }

  // ── Handle tap on a nearby city pin ───────────────────────────────────
  void _onCityPinTap(_NearbyCity city) {
    final loc = _TappedLocation(
      cityName: city.name,
      lat: city.lat,
      lon: city.lon,
      temp: city.temp,
      feelsLike: city.feelsLike,
      tempMin: city.tempMin,
      tempMax: city.tempMax,
      humidity: city.humidity,
      windSpeed: city.windSpeed,
      pressure: city.pressure,
      description: city.description,
      condition: city.condition,
      visibility: city.visibility,
      cloudiness: city.cloudiness,
    );
    setState(() => _tappedLocation = loc);
    _showWeatherSheet(loc);
  }

  // ── Beautiful bottom sheet ─────────────────────────────────────────────
  void _showWeatherSheet(_TappedLocation loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeatherBottomSheet(
        location: loc,
        onSetDefault: () {
          Navigator.pop(context); // close sheet
          // Fire event on the parent BLoC so the whole app switches
          context.read<WeatherBloc>().add(GetWeatherForCity(loc.cityName));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('${loc.cityName} set as default location'),
              ]),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _searchBarController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Toggle search bar ─────────────────────────────────────────────────
  void _toggleSearch() {
    if (_searchBarVisible) {
      _searchBarController.reverse().then((_) {
        if (mounted) setState(() { _searchBarVisible = false; _suggestions = []; });
      });
      _searchController.clear();
      _searchFocus.unfocus();
    } else {
      setState(() => _searchBarVisible = true);
      _searchBarController.forward();
      Future.delayed(const Duration(milliseconds: 100), () => _searchFocus.requestFocus());
    }
  }

  // ── Fetch city suggestions from OWM geocoding API ─────────────────────
  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2 || query == _lastQuery) return;
    _lastQuery = query;
    setState(() => _loadingSuggestions = true);
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(query)}&limit=5&appid=${ApiConstants.apiKey}',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200 && mounted) {
        final List<dynamic> results = json.decode(resp.body) as List<dynamic>;
        setState(() {
          _suggestions = results.map((e) => _SearchSuggestion(
            name:    e['name'] ?? '',
            country: e['country'] ?? '',
            state:   e['state'] ?? '',
            lat:     (e['lat'] as num).toDouble(),
            lon:     (e['lon'] as num).toDouble(),
          )).toList();
          _loadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  // ── Search and navigate to a suggestion ───────────────────────────────
  Future<void> _selectSuggestion(_SearchSuggestion s) async {
    _searchFocus.unfocus();
    setState(() { _suggestions = []; _searchingCity = true; _searchController.text = '${s.name}, ${s.country}'; });
    try {
      final data = await _fetchWeatherByLatLon(s.lat, s.lon);
      if (data != null && mounted) {
        final loc = _TappedLocation.fromApi(data, s.lat, s.lon);
        setState(() { _tappedLocation = loc; _searchingCity = false; });
        _mapController.move(LatLng(s.lat, s.lon), 10);
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) _showWeatherSheet(loc);
      }
    } catch (_) {
      if (mounted) setState(() => _searchingCity = false);
    }
  }

  IconData _conditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return Icons.wb_sunny_rounded;
      case 'clouds':       return Icons.cloud_rounded;
      case 'rain':         return Icons.water_drop_rounded;
      case 'drizzle':      return Icons.grain_rounded;
      case 'thunderstorm': return Icons.bolt_rounded;
      case 'snow':         return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
      case 'haze':         return Icons.blur_on_rounded;
      default:             return Icons.cloud_rounded;
    }
  }

  Color _tempColor(double temp) {
    if (temp < 0)  return Colors.lightBlue;
    if (temp < 10) return Colors.blue;
    if (temp < 20) return Colors.green;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final centerLatLng = LatLng(_lat, _lon);
    final owmLayer = _layers.firstWhere((l) => l.id == _selectedLayer).owmLayer;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _searchBarVisible
            ? FadeTransition(
                opacity: _searchBarOpacity,
                child: SizeTransition(
                  sizeFactor: _searchBarWidth,
                  axis: Axis.horizontal,
                  axisAlignment: -1,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            cursorColor: Colors.blue,
                            decoration: const InputDecoration(
                              hintText: 'Search city or country...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: _fetchSuggestions,
                            onSubmitted: (v) {
                              if (_suggestions.isNotEmpty) _selectSuggestion(_suggestions.first);
                            },
                          ),
                        ),
                        if (_loadingSuggestions || _searchingCity)
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: SizedBox(width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                          )
                        else if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () { _searchController.clear(); setState(() => _suggestions = []); _searchFocus.requestFocus(); },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : const Text('Weather Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: IconButton(
              key: ValueKey(_searchBarVisible),
              icon: Icon(
                _searchBarVisible ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
              ),
              onPressed: _toggleSearch,
            ),
          ),
          if (!_searchBarVisible)
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: Colors.white),
              onPressed: () => _mapController.move(centerLatLng, 9),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            // ── Interactive Map ──────────────────────────────
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerLatLng,
                      initialZoom: 8,
                      minZoom: 3,
                      maxZoom: 14,
                      onTap: _onMapTap,   // ← tap anywhere to get weather
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.diya.skypulse',
                        tileBuilder: _darkTileBuilder,
                      ),
                      TileLayer(
                        urlTemplate:
                            'https://tile.openweathermap.org/map/$owmLayer/{z}/{x}/{y}.png?appid=${ApiConstants.apiKey}',
                        // opacity: 0.55,
                        userAgentPackageName: 'com.diya.skypulse',
                      ),
                      MarkerLayer(
                        markers: [
                          // ── Current city pin ──────────────
                          Marker(
                            point: centerLatLng,
                            width: 130,
                            height: 70,
                            child: GestureDetector(
                              onTap: () => _onCityPinTap(_NearbyCity(
                                name: widget.weather.cityName,
                                lat: _lat,
                                lon: _lon,
                                temp: widget.weather.temperature,
                                feelsLike: widget.weather.feelsLike,
                                tempMin: widget.weather.tempMin,
                                tempMax: widget.weather.tempMax,
                                humidity: widget.weather.humidity,
                                windSpeed: widget.weather.windSpeed,
                                pressure: widget.weather.pressure,
                                description: widget.weather.description,
                                condition: widget.weather.mainCondition,
                                visibility: widget.weather.visibility,
                                cloudiness: widget.weather.cloudiness,
                              )),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.scale(
                                          scale: _pulse.value,
                                          child: Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.blue.withValues(alpha: 0.4), width: 2),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[800],
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)],
                                          ),
                                          child: Text(
                                            '${widget.weather.temperature.round()}°',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.weather.cityName,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Nearby city pins ──────────────
                          ..._nearbyCities.map((city) => Marker(
                            point: LatLng(city.lat, city.lon),
                            width: 90,
                            height: 60,
                            child: GestureDetector(
                              onTap: () => _onCityPinTap(city),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _tempColor(city.temp),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [BoxShadow(color: _tempColor(city.temp).withValues(alpha: 0.5), blurRadius: 6)],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_conditionIcon(city.condition), color: Colors.white, size: 11),
                                        const SizedBox(width: 3),
                                        Text('${city.temp.round()}°',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      city.name,
                                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                          // ── Tapped custom location pin ────
                          if (_tappedLocation != null)
                            Marker(
                              point: LatLng(_tappedLocation!.lat, _tappedLocation!.lon),
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.6), blurRadius: 10)],
                                ),
                                child: const Icon(Icons.push_pin_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // City info card (top-left)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 64, 12, 0),
                      child: _buildInfoCard(),
                    ),
                  ),

                  // ── Search suggestions dropdown ───────────
                  if (_searchBarVisible && _suggestions.isNotEmpty)
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 62, 16, 0),
                          child: AnimatedOpacity(
                            opacity: _suggestions.isNotEmpty ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 280),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A).withValues(alpha: 0.97),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.07),
                                  ),
                                  itemBuilder: (context, i) {
                                    final s = _suggestions[i];
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _selectSuggestion(s),
                                        borderRadius: BorderRadius.circular(18),
                                        splashColor: Colors.blue.withValues(alpha: 0.15),
                                        highlightColor: Colors.blue.withValues(alpha: 0.08),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF1565C0), Color(0xFF0A2472)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8)],
                                                ),
                                                child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 18),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      [if (s.state.isNotEmpty) s.state, s.country].join(', '),
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.5),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 64),
                        child: Container(
                          margin: const EdgeInsets.only(top: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded, color: Colors.white60, size: 13),
                              SizedBox(width: 5),
                              Text('Tap map or pin to see weather', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Zoom controls
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(children: [
                      _mapBtn(Icons.add_rounded,    () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 8),
                      _mapBtn(Icons.remove_rounded, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                    ]),
                  ),

                  // Fetching indicator
                  if (_fetchingTapped)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                            SizedBox(width: 12),
                            Text('Fetching weather...', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),

                  // Loading nearby badge
                  if (_loadingNearby)
                    Positioned(
                      bottom: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 8),
                            Text('Loading nearby...', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Layer Selector & Stats ───────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5C),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Map Layers', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.circle, color: Colors.green, size: 7),
                        SizedBox(width: 5),
                        Text('Live', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _layers.map((layer) {
                        final selected = _selectedLayer == layer.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedLayer = layer.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: selected ? LinearGradient(colors: [layer.color.withValues(alpha: 0.8), layer.color]) : null,
                              color: selected ? null : const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selected ? layer.color : Colors.white.withValues(alpha: 0.1)),
                              boxShadow: selected ? [BoxShadow(color: layer.color.withValues(alpha: 0.4), blurRadius: 10)] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(layer.icon, color: selected ? Colors.white : layer.color, size: 16),
                                const SizedBox(width: 6),
                                Text(layer.name, style: TextStyle(
                                    color: selected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _statChip(Icons.water_drop_rounded, '${widget.weather.humidity}%',                       'Humidity', Colors.blue),
                    const SizedBox(width: 8),
                    _statChip(Icons.air_rounded,         '${widget.weather.windSpeed.toStringAsFixed(1)} m/s', 'Wind',     Colors.teal),
                    const SizedBox(width: 8),
                    _statChip(Icons.compress_rounded,    '${widget.weather.pressure} hPa',                    'Pressure', Colors.purple),
                  ]),
                  if (widget.embedded) const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.weather.cityName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(widget.weather.description,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${widget.weather.temperature.round()}°C',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 3),
          Text(value,  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(label,  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9)),
        ]),
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1B3A5C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Weather Bottom Sheet
// ════════════════════════════════════════════════════════════════════════════

class _WeatherBottomSheet extends StatefulWidget {
  final _TappedLocation location;
  final VoidCallback onSetDefault;
  const _WeatherBottomSheet({required this.location, required this.onSetDefault});

  @override
  State<_WeatherBottomSheet> createState() => _WeatherBottomSheetState();
}

class _WeatherBottomSheetState extends State<_WeatherBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  IconData _condIcon(String c) {
    switch (c.toLowerCase()) {
      case 'clear':        return Icons.wb_sunny_rounded;
      case 'clouds':       return Icons.cloud_rounded;
      case 'rain':         return Icons.water_drop_rounded;
      case 'drizzle':      return Icons.grain_rounded;
      case 'thunderstorm': return Icons.bolt_rounded;
      case 'snow':         return Icons.ac_unit_rounded;
      default:             return Icons.cloud_rounded;
    }
  }

  List<Color> _gradientFor(String c) {
    switch (c.toLowerCase()) {
      case 'clear':        return [const Color(0xFFFF8C00), const Color(0xFFE65100)];
      case 'clouds':       return [const Color(0xFF546E7A), const Color(0xFF263238)];
      case 'rain':
      case 'drizzle':      return [const Color(0xFF1565C0), const Color(0xFF0A2472)];
      case 'thunderstorm': return [const Color(0xFF4A148C), const Color(0xFF1A0033)];
      case 'snow':         return [const Color(0xFF90CAF9), const Color(0xFF42A5F5)];
      default:             return [const Color(0xFF1565C0), const Color(0xFF0A2472)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final grad = _gradientFor(loc.condition);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF0D1B2A),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),

              // ── Hero gradient header ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grad),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    // Left: city + condition
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 15),
                            const SizedBox(width: 4),
                            Flexible(child: Text(loc.cityName,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 4),
                          Text(loc.description.toUpperCase(),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11, letterSpacing: 1.5)),
                          const SizedBox(height: 14),
                          Row(children: [
                            Text('${loc.tempMin.round()}° / ${loc.tempMax.round()}°',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Feels ${loc.feelsLike.round()}°',
                                  style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    // Right: big temperature + icon
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(_condIcon(loc.condition), color: Colors.white, size: 42),
                        const SizedBox(height: 4),
                        Text('${loc.temp.round()}°C',
                            style: const TextStyle(color: Colors.white, fontSize: 36,
                                fontWeight: FontWeight.w200, height: 1.0)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Detail grid ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _detailTile(Icons.water_drop_rounded,   '${loc.humidity}%',                           'Humidity',   Colors.blue),
                    _detailTile(Icons.air_rounded,           '${loc.windSpeed.toStringAsFixed(1)} m/s',    'Wind',       Colors.teal),
                    _detailTile(Icons.compress_rounded,      '${loc.pressure} hPa',                       'Pressure',   Colors.purple),
                    _detailTile(Icons.visibility_rounded,    '${(loc.visibility / 1000).toStringAsFixed(1)} km', 'Visibility', Colors.orange),
                    _detailTile(Icons.cloud_rounded,         '${loc.cloudiness}%',                         'Clouds',     Colors.blueGrey),
                    _detailTile(Icons.location_on_rounded,   '${loc.lat.toStringAsFixed(2)}, ${loc.lon.toStringAsFixed(2)}', 'Coords', Colors.green),
                  ],
                ),
              ),

              // ── Action buttons ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(children: [
                  // Dismiss
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white60,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Set as Default  ← main CTA
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: widget.onSetDefault,
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text('Set as Default', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: grad.first,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: grad.first.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Dark tile builder
// ════════════════════════════════════════════════════════════════════════════

Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      0.22, 0, 0, 0, 0,
      0, 0.28, 0, 0, 0,
      0, 0, 0.40, 0, 0,
      0, 0, 0,    1, 0,
    ]),
    child: tileWidget,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// Models
// ════════════════════════════════════════════════════════════════════════════

class _MapLayer {
  final String id, name, owmLayer;
  final IconData icon;
  final Color color;
  _MapLayer(this.id, this.name, this.icon, this.color, this.owmLayer);
}

/// Full weather data for a tapped / pinned location
class _TappedLocation {
  final String cityName, description, condition;
  final double lat, lon, temp, feelsLike, tempMin, tempMax, windSpeed;
  final int humidity, pressure, visibility, cloudiness;

  _TappedLocation({
    required this.cityName, required this.lat, required this.lon,
    required this.temp, required this.feelsLike, required this.tempMin,
    required this.tempMax, required this.humidity, required this.windSpeed,
    required this.pressure, required this.description, required this.condition,
    required this.visibility, required this.cloudiness,
  });

  factory _TappedLocation.fromApi(Map<String, dynamic> data, double lat, double lon) {
    return _TappedLocation(
      cityName:    data['name'] ?? 'Unknown',
      lat:         lat,
      lon:         lon,
      temp:        (data['main']['temp'] as num).toDouble(),
      feelsLike:   (data['main']['feels_like'] as num).toDouble(),
      tempMin:     (data['main']['temp_min'] as num).toDouble(),
      tempMax:     (data['main']['temp_max'] as num).toDouble(),
      humidity:    data['main']['humidity'] as int,
      pressure:    data['main']['pressure'] as int,
      windSpeed:   (data['wind']['speed'] as num).toDouble(),
      description: data['weather'][0]['description'] ?? '',
      condition:   data['weather'][0]['main'] ?? 'Clear',
      visibility:  (data['visibility'] as num?)?.toInt() ?? 10000,
      cloudiness:  data['clouds']['all'] as int,
    );
  }
}

/// Nearby city data (superset so we can reuse in bottom sheet)
class _NearbyCity {
  final String name, condition, description;
  final double lat, lon, temp, feelsLike, tempMin, tempMax, windSpeed;
  final int humidity, pressure, visibility, cloudiness;

  _NearbyCity({
    required this.name, required this.lat, required this.lon,
    required this.temp, required this.feelsLike, required this.tempMin,
    required this.tempMax, required this.humidity, required this.windSpeed,
    required this.pressure, required this.description, required this.condition,
    required this.visibility, required this.cloudiness,
  });

  factory _NearbyCity.fromApi(Map<String, dynamic> data) {
    return _NearbyCity(
      name:        data['name'] ?? '',
      lat:         (data['coord']['lat'] as num).toDouble(),
      lon:         (data['coord']['lon'] as num).toDouble(),
      temp:        (data['main']['temp'] as num).toDouble(),
      feelsLike:   (data['main']['feels_like'] as num).toDouble(),
      tempMin:     (data['main']['temp_min'] as num).toDouble(),
      tempMax:     (data['main']['temp_max'] as num).toDouble(),
      humidity:    data['main']['humidity'] as int,
      pressure:    data['main']['pressure'] as int,
      windSpeed:   (data['wind']['speed'] as num).toDouble(),
      description: data['weather'][0]['description'] ?? '',
      condition:   data['weather'][0]['main'] ?? 'Clear',
      visibility:  (data['visibility'] as num?)?.toInt() ?? 10000,
      cloudiness:  data['clouds']['all'] as int,
    );
  }
}

/// Geocoding search result
class _SearchSuggestion {
  final String name, country, state;
  final double lat, lon;
  _SearchSuggestion({
    required this.name,
    required this.country,
    required this.state,
    required this.lat,
    required this.lon,
  });
}

