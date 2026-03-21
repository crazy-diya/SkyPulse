import 'dart:math';
import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _rotate;
  late Animation<double> _pulse;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    _rotate = Tween<double>(begin: 0, end: 2 * pi)
        .animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear));
    _pulse = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinning ring + pulsing icon
              AnimatedBuilder(
                animation: Listenable.merge([_rotateCtrl, _pulseCtrl]),
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      Transform.rotate(
                        angle: _rotate.value,
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: _SpinnerPainter(),
                        ),
                      ),
                      // Inner pulsing glow
                      Transform.scale(
                        scale: _pulse.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.blue.withValues(alpha: 0.4),
                                Colors.blue.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Icon
                      const Icon(Icons.wb_sunny_rounded,
                          color: Colors.white, size: 40),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Loading weather...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Fetching latest data',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13)),
            ],
          ),
        ),
      );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 55.0;

    // Gradient arc
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.blue.withValues(alpha: 0.5),
          Colors.blue,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.1)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2, pi * 1.5, false, paint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter _) => false;
}
