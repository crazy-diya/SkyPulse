import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/forecast_item.dart';
import '../../../../core/utils/date_formatter.dart';

class ForecastDetailsPage extends StatefulWidget {
  final List<ForecastItem> forecast;
  final String cityName;

  const ForecastDetailsPage({
    super.key,
    required this.forecast,
    required this.cityName,
  });

  @override
  State<ForecastDetailsPage> createState() => _ForecastDetailsPageState();
}

class _ForecastDetailsPageState extends State<ForecastDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _chartController;
  late Animation<double> _entrance;
  late Animation<double> _chart;
  int _selectedDayIndex = 0;

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
    _chartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _entrance = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _chart = CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic);
    _chartController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Map<String, List<ForecastItem>> _groupByDay() {
    final Map<String, List<ForecastItem>> days = {};
    for (final item in widget.forecast) {
      final key = DateFormatter.formatDate(item.dateTime);
      days.putIfAbsent(key, () => []).add(item);
    }
    return days;
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny_rounded;
      case 'clouds': return Icons.cloud_rounded;
      case 'rain': return Icons.water_drop_rounded;
      case 'drizzle': return Icons.grain_rounded;
      case 'thunderstorm': return Icons.bolt_rounded;
      case 'snow': return Icons.ac_unit_rounded;
      default: return Icons.cloud_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _groupByDay();
    final dayKeys = days.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('5-Day Forecast',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(widget.cityName,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _entrance,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Day tab selector
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildDayTabs(dayKeys),
                ),
              ),
            ),

            // Temperature mini chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildTempChart(
                    days[dayKeys[_selectedDayIndex]] ?? []),
              ),
            ),

            // Hourly list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: _buildHourlyList(
                    days[dayKeys[_selectedDayIndex]] ?? []),
              ),
            ),

            // All days overview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: _buildAllDaysOverview(days, dayKeys),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTabs(List<String> dayKeys) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(dayKeys.length, (i) {
          final selected = _selectedDayIndex == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = i);
              _chartController.reset();
              _chartController.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF0D47A1)])
                    : null,
                color: selected ? null : const Color(0xFF1B3A5C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? Colors.blue
                      : Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: selected
                    ? [BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
                        blurRadius: 12)]
                    : [],
              ),
              child: Text(
                i == 0 ? 'Today' : dayKeys[i],
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTempChart(List<ForecastItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final temps = items.map((e) => e.temperature).toList();
    final maxT = temps.reduce((a, b) => a > b ? a : b);
    final minT = temps.reduce((a, b) => a < b ? a : b);
    final range = (maxT - minT).clamp(1.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Temperature Trend',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _chart,
            builder: (context, _) => CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _TempChartPainter(
                  temps: temps,
                  maxT: maxT,
                  minT: minT,
                  range: range,
                  progress: _chart.value),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items
                .map((e) => Text(
                      DateFormatter.formatTime(e.dateTime),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyList(List<ForecastItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hourly Details',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return TweenAnimationBuilder<Offset>(
            tween: Tween(begin: const Offset(0.3, 0), end: Offset.zero),
            duration: Duration(milliseconds: 300 + i * 60),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) => Transform.translate(
              offset: offset * 30,
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A5C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  // Time
                  SizedBox(
                    width: 45,
                    child: Text(
                      DateFormatter.formatTime(item.dateTime),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13),
                    ),
                  ),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getWeatherIcon(item.mainCondition),
                        color: Colors.blue[300], size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        Text(
                            '💧 ${item.humidity}%  💨 ${item.windSpeed.toStringAsFixed(1)} m/s',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  // Temperature
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.temperature.round()}°',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      Text(
                          '${item.tempMin.round()}° / ${item.tempMax.round()}°',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAllDaysOverview(
      Map<String, List<ForecastItem>> days, List<String> dayKeys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Full Overview',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B3A5C),
            borderRadius: BorderRadius.circular(22),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayKeys.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            itemBuilder: (context, i) {
              final key = dayKeys[i];
              final items = days[key]!;
              final mid = items[items.length ~/ 2];
              final minT =
                  items.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
              final maxT =
                  items.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
              final avgHumidity =
                  items.map((e) => e.humidity).reduce((a, b) => a + b) ~/
                      items.length;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDayIndex = i);
                  _chartController.reset();
                  _chartController.forward();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedDayIndex == i
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(i == 0 ? 'Today' : key,
                            style: TextStyle(
                              color: _selectedDayIndex == i
                                  ? Colors.blue[300]
                                  : Colors.white.withValues(alpha: 0.85),
                              fontWeight: _selectedDayIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            )),
                      ),
                      Icon(_getWeatherIcon(mid.mainCondition),
                          color: Colors.white70, size: 22),
                      const SizedBox(width: 8),
                      Text('💧${avgHumidity}%',
                          style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 11)),
                      const Spacer(),
                      Text('${minT.round()}°',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13)),
                      const SizedBox(width: 8),
                      _MiniTempBar(
                          min: minT, max: maxT, allMin: -10, allMax: 45),
                      const SizedBox(width: 8),
                      Text('${maxT.round()}°',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
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

class _TempChartPainter extends CustomPainter {
  final List<double> temps;
  final double maxT, minT, range, progress;

  _TempChartPainter(
      {required this.temps,
      required this.maxT,
      required this.minT,
      required this.range,
      required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (temps.isEmpty) return;

    final step = size.width / (temps.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < temps.length; i++) {
      final x = i * step;
      final y = size.height -
          ((temps[i] - minT) / range) * size.height * 0.8 -
          size.height * 0.1;
      points.add(Offset(x, y));
    }

    // Clip to progress
    final clipWidth = size.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, clipWidth, size.height));

    // Fill gradient
    final fillPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.withValues(alpha: 0.3),
            Colors.blue.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = Colors.blue[400]!
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.blue[200]!);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TempChartPainter old) => old.progress != progress;
}

class _MiniTempBar extends StatelessWidget {
  final double min, max, allMin, allMax;
  const _MiniTempBar(
      {required this.min,
      required this.max,
      required this.allMin,
      required this.allMax});

  @override
  Widget build(BuildContext context) {
    final range = allMax - allMin;
    final l = (min - allMin) / range;
    final r = 1.0 - (max - allMin) / range;

    return Container(
      width: 70,
      height: 5,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        widthFactor: 1.0,
        child: Padding(
          padding: EdgeInsets.only(left: l * 70, right: r * 70),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.orange]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
