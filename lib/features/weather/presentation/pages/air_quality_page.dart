import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/weather.dart';
import '../../../../core/constants/api_constants.dart';

class AirQualityData {
  final int aqi;
  final double co, no, no2, o3, so2, pm2_5, pm10, nh3;
  AirQualityData({
    required this.aqi,
    required this.co,
    required this.no,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.pm2_5,
    required this.pm10,
    required this.nh3,
  });
}

class AirQualityPage extends StatefulWidget {
  final Weather weather;
  final bool embedded;
  const AirQualityPage({super.key, required this.weather, this.embedded = false});

  @override
  State<AirQualityPage> createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _entranceController;
  late Animation<double> _gaugeAnim;
  late Animation<double> _entrance;

  AirQualityData? _aqiData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    _gaugeAnim = CurvedAnimation(parent: _gaugeController, curve: Curves.easeOut);
    _entrance = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);

    _fetchAirQuality();
  }

  Future<void> _fetchAirQuality() async {
    try {
      // We need lat/lon — use weather cityName to get geocoding first
      final geoUrl = Uri.parse(
          'http://api.openweathermap.org/geo/1.0/direct?q=${widget.weather.cityName}&limit=1&appid=${ApiConstants.apiKey}');
      final geoResp = await http.get(geoUrl);
      if (geoResp.statusCode != 200) throw Exception('Geocoding failed');
      final geoData = json.decode(geoResp.body) as List;
      if (geoData.isEmpty) throw Exception('City not found');
      final lat = geoData[0]['lat'];
      final lon = geoData[0]['lon'];

      final aqUrl = Uri.parse(
          'http://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=${ApiConstants.apiKey}');
      final aqResp = await http.get(aqUrl);
      if (aqResp.statusCode != 200) throw Exception('Air quality fetch failed');
      final aqData = json.decode(aqResp.body);
      final list = aqData['list'][0];
      final comp = list['components'];

      setState(() {
        _aqiData = AirQualityData(
          aqi: list['main']['aqi'],
          co: comp['co']?.toDouble() ?? 0,
          no: comp['no']?.toDouble() ?? 0,
          no2: comp['no2']?.toDouble() ?? 0,
          o3: comp['o3']?.toDouble() ?? 0,
          so2: comp['so2']?.toDouble() ?? 0,
          pm2_5: comp['pm2_5']?.toDouble() ?? 0,
          pm10: comp['pm10']?.toDouble() ?? 0,
          nh3: comp['nh3']?.toDouble() ?? 0,
        );
        _loading = false;
      });
      _gaugeController.forward();
    } catch (e) {
      setState(() {
        _loading = false;
        // Fallback demo data
        _aqiData = AirQualityData(
          aqi: 2, co: 230, no: 0.15, no2: 5.2, o3: 68,
          so2: 0.6, pm2_5: 8.5, pm10: 15.2, nh3: 1.2,
        );
      });
      _gaugeController.forward();
    }
  }

  String _aqiLabel(int aqi) {
    switch (aqi) {
      case 1: return 'Good';
      case 2: return 'Fair';
      case 3: return 'Moderate';
      case 4: return 'Poor';
      case 5: return 'Very Poor';
      default: return 'Unknown';
    }
  }

  Color _aqiColor(int aqi) {
    switch (aqi) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.yellow;
      case 4: return Colors.orange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _aqiAdvice(int aqi) {
    switch (aqi) {
      case 1: return 'Air quality is satisfactory. Enjoy outdoor activities!';
      case 2: return 'Air quality is acceptable. Sensitive groups should take care.';
      case 3: return 'Sensitive groups may experience effects. Limit prolonged outdoor exertion.';
      case 4: return 'Health alert. Everyone may begin to experience health effects.';
      case 5: return 'Health warning. Avoid outdoor activities if possible.';
      default: return 'Data unavailable.';
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _entranceController.dispose();
    super.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Air Quality',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(widget.weather.cityName,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() => _loading = true);
              _fetchAirQuality();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.teal),
                  SizedBox(height: 16),
                  Text('Fetching air quality data...',
                      style: TextStyle(color: Colors.white60)),
                ],
              ),
            )
          : FadeTransition(
              opacity: _entrance,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final data = _aqiData!;
    final color = _aqiColor(data.aqi);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // AQI Gauge
                  _buildAqiGauge(data, color),
                  const SizedBox(height: 20),
                  // Advice card
                  _buildAdviceCard(data, color),
                  const SizedBox(height: 20),
                  // Pollutant grid
                  _buildPollutantsSection(data),
                  const SizedBox(height: 20),
                  // Health tips
                  _buildHealthTips(data.aqi),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAqiGauge(AirQualityData data, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            const Color(0xFF1B3A5C),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text('Air Quality Index',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _gaugeAnim,
            builder: (context, _) => CustomPaint(
              size: const Size(220, 120),
              painter: _AqiGaugePainter(
                  aqi: data.aqi, progress: _gaugeAnim.value, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(_aqiLabel(data.aqi),
              style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)])),
          Text('AQI: ${data.aqi} / 5',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(AirQualityData data, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.health_and_safety_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Health Advice',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(_aqiAdvice(data.aqi),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantsSection(AirQualityData data) {
    final pollutants = [
      _Pollutant('CO', data.co, 'µg/m³', 10000, Colors.orange),
      _Pollutant('NO₂', data.no2, 'µg/m³', 200, Colors.yellow),
      _Pollutant('O₃', data.o3, 'µg/m³', 180, Colors.blue),
      _Pollutant('SO₂', data.so2, 'µg/m³', 350, Colors.purple),
      _Pollutant('PM2.5', data.pm2_5, 'µg/m³', 75, Colors.red),
      _Pollutant('PM10', data.pm10, 'µg/m³', 150, Colors.deepOrange),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pollutants',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: pollutants.length,
          itemBuilder: (context, i) {
            final p = pollutants[i];
            final ratio = (p.value / p.maxSafe).clamp(0.0, 1.0);
            return AnimatedBuilder(
              animation: _gaugeAnim,
              builder: (context, _) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3A5C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.name,
                            style: TextStyle(
                                color: p.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const Spacer(),
                        Text(p.unit,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.value.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio * _gaugeAnim.value,
                        backgroundColor: p.color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(p.color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHealthTips(int aqi) {
    final tips = aqi <= 2
        ? [
            ('🏃', 'Great day for outdoor exercise'),
            ('🪟', 'Open windows for fresh air'),
            ('🌿', 'Perfect for outdoor activities'),
          ]
        : aqi == 3
            ? [
                ('😷', 'Sensitive groups wear masks'),
                ('🏠', 'Limit time outdoors'),
                ('💧', 'Stay well hydrated'),
              ]
            : [
                ('😷', 'Wear N95 mask outdoors'),
                ('🚪', 'Keep windows closed'),
                ('🏥', 'Check with doctor if symptomatic'),
              ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Health Tips',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tips.map((tip) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(tip.$1, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Text(tip.$2,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14)),
                ],
              ),
            )),
      ],
    );
  }
}

class _Pollutant {
  final String name, unit;
  final double value, maxSafe;
  final Color color;
  _Pollutant(this.name, this.value, this.unit, this.maxSafe, this.color);
}

class _AqiGaugePainter extends CustomPainter {
  final int aqi;
  final double progress;
  final Color color;
  _AqiGaugePainter({required this.aqi, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    const radius = 90.0;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi, pi, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Color segments
    final segColors = [Colors.green, Colors.lightGreen, Colors.yellow, Colors.orange, Colors.red];
    for (int i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        pi + (pi / 5) * i,
        pi / 5 * 0.85,
        false,
        Paint()
          ..color = segColors[i].withValues(alpha: 0.25)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Active arc
    final sweepAngle = (aqi / 5) * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi, sweepAngle, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: pi,
          endAngle: pi + sweepAngle,
          colors: [Colors.green, color],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Needle
    final needleAngle = pi + (aqi / 5) * pi * progress;
    final nx = cx + (radius) * cos(needleAngle);
    final ny = cy + (radius) * sin(needleAngle);
    canvas.drawCircle(Offset(nx, ny), 8, Paint()..color = color);
    canvas.drawCircle(
        Offset(nx, ny), 8, Paint()..color = color.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(_AqiGaugePainter old) => old.progress != progress;
}

