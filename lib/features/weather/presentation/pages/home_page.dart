import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';
import '../pages/forecast_details_page.dart';
import '../pages/search_page.dart';
import '../pages/saved_locations_page.dart';
import '../pages/settings_page.dart';
import '../pages/weather_map_page.dart';
import '../pages/air_quality_page.dart';
import '../pages/weather_compare_page.dart';
import '../widgets/error_widget.dart' as custom;
import '../widgets/loading_widget.dart';
import '../../domain/entities/weather.dart';
import '../../domain/entities/forecast_item.dart';
import '../../../../core/utils/date_formatter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WeatherBloc>()..add(const GetWeatherForCurrentLocation()),
      child: const _HomeShell(),
    );
  }
}

/// Shell that owns the bottom nav state and holds the BLoC for all tabs.
class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        final weather = state is WeatherLoaded ? state.weather : null;

        final pages = [
          const _HomeTab(),
          if (weather != null) WeatherMapPage(weather: weather, embedded: true)
          else const _PlaceholderTab(Icons.map_rounded, 'Loading map...'),
          if (weather != null) AirQualityPage(weather: weather, embedded: true)
          else const _PlaceholderTab(Icons.air_rounded, 'Loading air quality...'),
          if (weather != null) WeatherComparePage(currentWeather: weather, embedded: true)
          else const _PlaceholderTab(Icons.compare_arrows_rounded, 'Loading compare...'),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          extendBodyBehindAppBar: true,
          // Only show top appbar for the Home tab (index 0)
          appBar: _currentIndex == 0 ? _buildShellAppBar(context, weather) : null,
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() => _currentIndex = 0);
              context.read<WeatherBloc>().add(const GetWeatherForCurrentLocation());
            },
            backgroundColor: const Color(0xFF1565C0),
            elevation: 6,
            child: const Icon(Icons.my_location_rounded, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  PreferredSizeWidget _buildShellAppBar(BuildContext context, Weather? weather) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              weather?.cityName ?? 'SkyPulse',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchPage()));
            if (result != null && context.mounted) {
              context.read<WeatherBloc>().add(GetWeatherForCity(result.cityName));
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SavedLocationsPage()));
            if (result != null && context.mounted) {
              context.read<WeatherBloc>().add(GetWeatherForCity(result));
            }
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          color: const Color(0xFF1B3A5C),
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(children: [
                Icon(Icons.settings_rounded, color: Colors.white70, size: 20),
                SizedBox(width: 8),
                Text('Settings', style: TextStyle(color: Colors.white)),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.map_rounded, 'Map'),
      (Icons.air_rounded, 'Air'),
      (Icons.compare_arrows_rounded, 'Compare'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(top: BorderSide(color: Color(0xFF1B3A5C), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // Left two items
              for (int i = 0; i < 2; i++)
                Expanded(child: _NavItem(index: i, icon: items[i].$1, label: items[i].$2, selected: currentIndex == i, onTap: () => onTap(i))),
              // FAB gap
              const SizedBox(width: 72),
              // Right two items
              for (int i = 2; i < 4; i++)
                Expanded(child: _NavItem(index: i, icon: items[i].$1, label: items[i].$2, selected: currentIndex == i, onTap: () => onTap(i))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.index, required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? Colors.blue.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? Colors.blue[300] : Colors.white38, size: 24),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.blue[300] : Colors.white38,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder when weather not loaded yet ───────────

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _PlaceholderTab(this.icon, this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with TickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late AnimationController _weatherIconController;
  late AnimationController _bgController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _iconRotation;
  late Animation<double> _bgShift;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _contentAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _weatherIconController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);

    _headerFade = CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic));
    _contentFade = CurvedAnimation(parent: _contentAnimController, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentAnimController, curve: Curves.easeOutCubic));
    _iconRotation = Tween<double>(begin: -0.05, end: 0.05)
        .animate(CurvedAnimation(parent: _weatherIconController, curve: Curves.easeInOut));
    _bgShift = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimController.forward();
    });
  }

  void _restartAnimations() {
    _headerAnimController.reset();
    _contentAnimController.reset();
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    _weatherIconController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  List<Color> _getWeatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return [const Color(0xFFFF8C00), const Color(0xFFFF6B35), const Color(0xFFE65100)];
      case 'clouds': return [const Color(0xFF546E7A), const Color(0xFF37474F), const Color(0xFF263238)];
      case 'rain':
      case 'drizzle': return [const Color(0xFF1565C0), const Color(0xFF0D47A1), const Color(0xFF0A2472)];
      case 'thunderstorm': return [const Color(0xFF4A148C), const Color(0xFF311B92), const Color(0xFF1A0033)];
      case 'snow': return [const Color(0xFF90CAF9), const Color(0xFF64B5F6), const Color(0xFF42A5F5)];
      default: return [const Color(0xFF1565C0), const Color(0xFF0D47A1), const Color(0xFF0A2472)];
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny_rounded;
      case 'clouds': return Icons.cloud_rounded;
      case 'rain': return Icons.water_drop_rounded;
      case 'drizzle': return Icons.grain_rounded;
      case 'thunderstorm': return Icons.bolt_rounded;
      case 'snow': return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
      case 'haze': return Icons.blur_on_rounded;
      default: return Icons.cloud_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return BlocConsumer<WeatherBloc, WeatherState>(
      listener: (context, state) {
        if (state is WeatherLoaded) _restartAnimations();
        if (state is LocationPermissionRequired) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange[800],
            action: SnackBarAction(label: 'OK', onPressed: () {}, textColor: Colors.white),
          ));
        }
      },
      builder: (context, state) {
        if (state is WeatherLoading) return const LoadingWidget();
        if (state is WeatherError) {
          return custom.ErrorWidget(
            message: state.message,
            onRetry: () => context.read<WeatherBloc>().add(const GetWeatherForCurrentLocation()),
          );
        }

        final weather = state is WeatherLoaded ? state.weather : null;
        final forecast = state is WeatherLoaded ? state.forecast : <ForecastItem>[];
        final gradients = _getWeatherGradient(weather?.mainCondition ?? 'clear');

        if (weather == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        return RefreshIndicator(
          color: Colors.white,
          backgroundColor: gradients.first,
          onRefresh: () async =>
              context.read<WeatherBloc>().add(const GetWeatherForCurrentLocation()),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHeroHeader(context, weather, gradients)),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        _buildQuickStatsRow(weather),
                        _buildHourlyForecast(forecast),
                        _buildDetailsGrid(weather),
                        _buildSunriseSunset(weather),
                        _buildForecastSection(context, forecast, weather),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(BuildContext context, Weather weather, List<Color> gradients) {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: AnimatedBuilder(
          animation: _bgController,
          builder: (context, _) => Container(
            height: MediaQuery.of(context).size.height * 0.46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(gradients[0], gradients[1], _bgShift.value)!,
                  Color.lerp(gradients[1], gradients[2], _bgShift.value)!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(color: gradients.first.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(right: -60, top: 40, child: _decorCircle(250, 0.06)),
                Positioned(left: -80, bottom: 20, child: _decorCircle(200, 0.05)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Dynamically shrink content to always fit available height
                        final availH = constraints.maxHeight;
                        final iconSize = (availH * 0.32).clamp(70.0, 100.0);
                        final tempSize = (availH * 0.28).clamp(56.0, 82.0);
                        return SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _weatherIconController,
                                builder: (_, __) => Transform.rotate(
                                  angle: _iconRotation.value,
                                  child: Container(
                                    width: iconSize,
                                    height: iconSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.15),
                                      boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 4)],
                                    ),
                                    child: Icon(_getWeatherIcon(weather.mainCondition), size: iconSize * 0.58, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(height: availH * 0.02),
                              Text(
                                '${weather.temperature.round()}°',
                                style: TextStyle(fontSize: tempSize, fontWeight: FontWeight.w200, color: Colors.white, height: 1.0),
                              ),
                              Text(
                                weather.description.toUpperCase(),
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 2.5, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: availH * 0.03),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _headerPill(Icons.arrow_downward_rounded, '${weather.tempMin.round()}°', 'Low'),
                                  const SizedBox(width: 10),
                                  _headerPill(Icons.thermostat_rounded, '${weather.feelsLike.round()}°', 'Feels'),
                                  const SizedBox(width: 10),
                                  _headerPill(Icons.arrow_upward_rounded, '${weather.tempMax.round()}°', 'High'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );

  Widget _headerPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
      ]),
    );
  }

  Widget _buildQuickStatsRow(Weather weather) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(children: [
        _quickStatCard(Icons.water_drop_rounded, '${weather.humidity}%', 'Humidity', Colors.blue),
        const SizedBox(width: 10),
        _quickStatCard(Icons.air_rounded, '${weather.windSpeed.toStringAsFixed(1)} m/s', 'Wind', Colors.teal),
        const SizedBox(width: 10),
        _quickStatCard(Icons.visibility_rounded, '${(weather.visibility / 1000).toStringAsFixed(1)} km', 'Visibility', Colors.purple),
      ]),
    );
  }

  Widget _quickStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3A5C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildHourlyForecast(List<ForecastItem> forecast) {
    if (forecast.isEmpty) return const SizedBox.shrink();
    final hourly = forecast.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Hourly Forecast', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hourly.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = hourly[i];
              final isNow = i == 0;
              return Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isNow ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue[400]!, Colors.blue[700]!]) : null,
                  color: isNow ? null : const Color(0xFF1B3A5C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isNow ? Colors.blue[300]! : Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(isNow ? 'Now' : DateFormatter.formatTime(item.dateTime),
                      style: TextStyle(color: isNow ? Colors.white : Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                  Icon(_getWeatherIcon(item.mainCondition), color: Colors.white, size: 26),
                  Text('${item.temperature.round()}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildDetailsGrid(Weather weather) {
    final details = [
      _DetailItem(Icons.compress_rounded, 'Pressure', '${weather.pressure} hPa', Colors.orange),
      _DetailItem(Icons.cloud_rounded, 'Cloudiness', '${weather.cloudiness}%', Colors.blueGrey),
      _DetailItem(Icons.thermostat_rounded, 'Feels Like', '${weather.feelsLike.round()}°C', Colors.red),
      _DetailItem(Icons.water_rounded, 'Humidity', '${weather.humidity}%', Colors.blue),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Weather Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: details.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemBuilder: (_, i) {
            final d = details[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: d.color.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: d.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(d.icon, color: d.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(d.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ])),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildSunriseSunset(Weather weather) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3A5C),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sun Schedule', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _SunArcWidget(weather: weather),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _sunTimeItem(Icons.wb_twilight_rounded, 'Sunrise', DateFormatter.formatTime(weather.sunrise), Colors.orange)),
            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
            Expanded(child: _sunTimeItem(Icons.nights_stay_rounded, 'Sunset', DateFormatter.formatTime(weather.sunset), Colors.deepOrange)),
          ]),
        ]),
      ),
    );
  }

  Widget _sunTimeItem(IconData icon, String label, String time, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
      const SizedBox(height: 2),
      Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }

  Widget _buildForecastSection(BuildContext context, List<ForecastItem> forecast, Weather weather) {
    if (forecast.isEmpty) return const SizedBox.shrink();
    final Map<String, List<ForecastItem>> days = {};
    for (final item in forecast) {
      final key = DateFormatter.formatDate(item.dateTime);
      days.putIfAbsent(key, () => []).add(item);
    }
    final dayKeys = days.keys.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('5-Day Forecast', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForecastDetailsPage(forecast: forecast, cityName: weather.cityName))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
              ),
              child: const Text('See All', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1B3A5C), borderRadius: BorderRadius.circular(22)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayKeys.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
            itemBuilder: (_, i) {
              final key = dayKeys[i];
              final items = days[key]!;
              final mid = items[items.length ~/ 2];
              final minT = items.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
              final maxT = items.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [
                  SizedBox(width: 80, child: Text(i == 0 ? 'Today' : key,
                      style: TextStyle(color: i == 0 ? Colors.blue[300] : Colors.white.withValues(alpha: 0.85), fontWeight: i == 0 ? FontWeight.bold : FontWeight.w500, fontSize: 14))),
                  Icon(_getWeatherIcon(mid.mainCondition), color: Colors.white70, size: 24),
                  const Spacer(),
                  Text('${minT.round()}°', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                  const SizedBox(width: 8),
                  _TempBar(min: minT, max: maxT, allMin: -10, allMax: 45),
                  const SizedBox(width: 8),
                  Text('${maxT.round()}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Helper classes ────────────────────────────────────

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _DetailItem(this.icon, this.label, this.value, this.color);
}

// ── Sun Arc ───────────────────────────────────────────

class _SunArcWidget extends StatefulWidget {
  final Weather weather;
  const _SunArcWidget({required this.weather});
  @override
  State<_SunArcWidget> createState() => _SunArcWidgetState();
}

class _SunArcWidgetState extends State<_SunArcWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    final now = DateTime.now();
    final total = widget.weather.sunset.difference(widget.weather.sunrise).inMinutes.toDouble();
    final elapsed = now.difference(widget.weather.sunrise).inMinutes.toDouble();
    final p = (elapsed / total).clamp(0.0, 1.0);
    _progress = Tween<double>(begin: 0, end: p).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) => CustomPaint(size: const Size(double.infinity, 60), painter: _SunArcPainter(progress: _progress.value)),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  final double progress;
  _SunArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const LinearGradient(colors: [Colors.orange, Colors.deepOrange])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(20, 0, size.width - 40, size.height * 2);
    canvas.drawArc(rect, pi, pi, false, trackPaint);
    canvas.drawArc(rect, pi, pi * progress, false, progressPaint);

    final angle = pi + pi * progress;
    final cx = rect.center.dx + (rect.width / 2) * cos(angle);
    final cy = rect.center.dy + (rect.height / 2) * sin(angle);
    canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = Colors.orange);
    canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = Colors.orange.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.progress != progress;
}

// ── Temperature bar ───────────────────────────────────

class _TempBar extends StatelessWidget {
  final double min, max, allMin, allMax;
  const _TempBar({required this.min, required this.max, required this.allMin, required this.allMax});

  @override
  Widget build(BuildContext context) {
    final range = allMax - allMin;
    final left = (min - allMin) / range;
    final right = 1.0 - (max - allMin) / range;
    return Container(
      width: 80, height: 6,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 1.0,
        child: Padding(
          padding: EdgeInsets.only(left: left * 80, right: right * 80),
          child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.blue, Colors.orange]), borderRadius: BorderRadius.circular(3))),
        ),
      ),
    );
  }
}
