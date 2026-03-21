import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';
import '../../domain/entities/weather.dart';

class WeatherComparePage extends StatefulWidget {
  final Weather currentWeather;
  final bool embedded;
  const WeatherComparePage({super.key, required this.currentWeather, this.embedded = false});

  @override
  State<WeatherComparePage> createState() => _WeatherComparePageState();
}

class _WeatherComparePageState extends State<WeatherComparePage>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _barController;
  late Animation<double> _entrance;
  late Animation<double> _bar;

  final TextEditingController _searchCtrl = TextEditingController();
  Weather? _comparedWeather;
  bool _loadingCompare = false;
  String? _compareError;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _entrance = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _bar = CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic);
  }

  void _searchCity(String city) async {
    if (city.trim().isEmpty) return;
    setState(() {
      _loadingCompare = true;
      _compareError = null;
      _comparedWeather = null;
    });
    _barController.reset();

    // Reuse weather bloc — use a new instance
    final bloc = sl<WeatherBloc>();
    bloc.add(GetWeatherForCity(city.trim()));

    await for (final state in bloc.stream) {
      if (state is WeatherLoaded) {
        if (mounted) {
          setState(() {
            _comparedWeather = state.weather;
            _loadingCompare = false;
          });
          _barController.forward();
        }
        bloc.close();
        break;
      } else if (state is WeatherError) {
        if (mounted) {
          setState(() {
            _compareError = state.message;
            _loadingCompare = false;
          });
        }
        bloc.close();
        break;
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _barController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny_rounded;
      case 'clouds': return Icons.cloud_rounded;
      case 'rain': return Icons.water_drop_rounded;
      case 'thunderstorm': return Icons.bolt_rounded;
      case 'snow': return Icons.ac_unit_rounded;
      default: return Icons.cloud_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Compare Cities',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FadeTransition(
        opacity: _entrance,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(child: _buildCityHeader(widget.currentWeather, Colors.blue, 'Current')),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.compare_arrows_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          Expanded(
                            child: _comparedWeather != null
                                ? _buildCityHeader(_comparedWeather!, Colors.teal, 'Compared')
                                : _buildEmptyCity(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Search field
                      _buildSearchField(),
                      const SizedBox(height: 8),

                      if (_compareError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_compareError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                        ),

                      if (_loadingCompare)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: CircularProgressIndicator(color: Colors.teal)),
                        ),

                      if (_comparedWeather != null) ...[
                        const SizedBox(height: 20),
                        _buildCompareSection(),
                      ],

                      if (_comparedWeather == null && !_loadingCompare)
                        _buildSuggestionsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityHeader(Weather w, Color color, String tag) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tag,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Icon(_getWeatherIcon(w.mainCondition), color: Colors.white, size: 32),
          const SizedBox(height: 6),
          Text('${w.temperature.round()}°',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w200)),
          Text(w.cityName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(w.description,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyCity() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.add_location_alt_rounded,
              color: Colors.white.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: 8),
          Text('Search a city\nto compare',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onSubmitted: _searchCity,
            decoration: InputDecoration(
              hintText: 'Search city to compare...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: const Color(0xFF1B3A5C),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: Colors.teal.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _searchCity(_searchCtrl.text),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF004D40)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareSection() {
    final w1 = widget.currentWeather;
    final w2 = _comparedWeather!;

    final metrics = [
      _Metric('Temperature', w1.temperature, w2.temperature, '°C',
          Icons.thermostat_rounded, Colors.red, 60),
      _Metric('Humidity', w1.humidity.toDouble(), w2.humidity.toDouble(), '%',
          Icons.water_drop_rounded, Colors.blue, 100),
      _Metric('Wind Speed', w1.windSpeed, w2.windSpeed, 'm/s',
          Icons.air_rounded, Colors.teal, 50),
      _Metric('Pressure', w1.pressure.toDouble(), w2.pressure.toDouble(), 'hPa',
          Icons.compress_rounded, Colors.purple, 1100),
      _Metric('Feels Like', w1.feelsLike, w2.feelsLike, '°C',
          Icons.device_thermostat_rounded, Colors.orange, 60),
      _Metric('Visibility', w1.visibility / 1000, w2.visibility / 1000, 'km',
          Icons.visibility_rounded, Colors.indigo, 20),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _colorDot(Colors.blue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(w1.cityName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            _colorDot(Colors.teal),
            const SizedBox(width: 6),
            Expanded(
              child: Text(w2.cityName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...metrics.map((m) => AnimatedBuilder(
              animation: _bar,
              builder: (context, _) => _buildMetricBar(m, _bar.value),
            )),
        const SizedBox(height: 20),
        _buildSummaryCard(w1, w2),
      ],
    );
  }

  Widget _colorDot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );

  Widget _buildMetricBar(_Metric m, double progress) {
    final r1 = (m.v1.abs() / m.max).clamp(0.0, 1.0) * progress;
    final r2 = (m.v2.abs() / m.max).clamp(0.0, 1.0) * progress;
    final v1Wins = m.v1 > m.v2;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(m.icon, color: m.color, size: 16),
              const SizedBox(width: 8),
              Text(m.label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
              const Spacer(),
              Text('${m.v1.toStringAsFixed(1)} ${m.unit}',
                  style: TextStyle(
                      color: v1Wins ? Colors.blue[300] : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(width: 8),
              Text('vs',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
              const SizedBox(width: 8),
              Text('${m.v2.toStringAsFixed(1)} ${m.unit}',
                  style: TextStyle(
                      color: !v1Wins ? Colors.teal[300] : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // City 1 bar (right-to-center)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: r1,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.blue.withValues(alpha: 0.5), Colors.blue]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                  width: 2, height: 14, color: Colors.white.withValues(alpha: 0.2)),
              // City 2 bar (left-to-center)
              Expanded(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: r2,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.teal, Colors.teal.withValues(alpha: 0.5)]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Weather w1, Weather w2) {
    final tempDiff = (w1.temperature - w2.temperature).abs();
    final w1warmer = w1.temperature > w2.temperature;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.3),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.indigo, size: 20),
              SizedBox(width: 8),
              Text('Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${w1warmer ? w1.cityName : w2.cityName} is ${tempDiff.toStringAsFixed(1)}°C warmer than '
            '${w1warmer ? w2.cityName : w1.cityName}.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Humidity difference: ${(w1.humidity - w2.humidity).abs()}%  •  '
            'Wind difference: ${(w1.windSpeed - w2.windSpeed).abs().toStringAsFixed(1)} m/s',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    final suggestions = [
      'New York', 'Dubai', 'London', 'Tokyo', 'Paris', 'Mumbai',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Comparisons',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((city) {
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = city;
                  _searchCity(city);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3A5C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.teal, size: 14),
                      const SizedBox(width: 6),
                      Text(city,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String label, unit;
  final double v1, v2, max;
  final IconData icon;
  final Color color;
  _Metric(this.label, this.v1, this.v2, this.unit, this.icon, this.color, this.max);
}

