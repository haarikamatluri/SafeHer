import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Painter for Route Preview & Active Tracking (Screens A3 & A4)
class RouteMapPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 along route
  final bool showAlternative;
  final bool isNightMode;
  final String destinationTitle;

  RouteMapPainter({
    this.progress = 0.45,
    this.showAlternative = true,
    this.isNightMode = true,
    this.destinationTitle = 'Sri Venkateswara University',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background map terrain
    final bgPaint = Paint()
      ..color = isNightMode ? const Color(0xFF1E262C) : const Color(0xFFE8F0E9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle park/green zones
    final parkPaint = Paint()
      ..color = isNightMode
          ? const Color(0xFF25332C).withValues(alpha: 0.6)
          : const Color(0xFFCCE8D2);
    final parkPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.15, size.width * 0.4, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.15, size.height * 0.4)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    final parkPath2 = Path()
      ..moveTo(size.width * 0.65, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.55, size.width * 0.9, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.85, size.width * 0.65, size.height * 0.6)
      ..close();
    canvas.drawPath(parkPath2, parkPaint);

    // Subtle secondary roads
    final roadPaint = Paint()
      ..color = isNightMode ? const Color(0xFF2C3942) : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.4, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.65, size.height),
      roadPaint,
    );

    // Main Recommended Route Polyline (Glowing Blue / Magenta)
    final routePath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.3,
        size.width * 0.78,
        size.height * 0.18,
      );

    // Alternative Route (Grey dashed)
    if (showAlternative) {
      final altPath = Path()
        ..moveTo(size.width * 0.25, size.height * 0.8)
        ..cubicTo(
          size.width * 0.15,
          size.height * 0.6,
          size.width * 0.3,
          size.height * 0.3,
          size.width * 0.5,
          size.height * 0.22,
        )
        ..lineTo(size.width * 0.78, size.height * 0.18);

      final altPaint = Paint()
        ..color = isNightMode ? Colors.white30 : Colors.black26
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(altPath, altPaint);
    }

    // Outer glow for active route
    final glowPaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, glowPaint);

    // Main solid route
    final mainRoutePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, mainRoutePaint);

    // Origin Pin (Bottom Left)
    final originOffset = Offset(size.width * 0.25, size.height * 0.8);
    final originPaint = Paint()..color = SafeHerColors.successGreen;
    canvas.drawCircle(originOffset, 7, originPaint);
    canvas.drawCircle(
      originOffset,
      12,
      Paint()
        ..color = SafeHerColors.successGreen.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Destination Pin (Top Right)
    final destOffset = Offset(size.width * 0.78, size.height * 0.18);
    final destPaint = Paint()..color = SafeHerColors.primaryRose;
    canvas.drawCircle(destOffset, 8, destPaint);
    canvas.drawCircle(
      destOffset,
      14,
      Paint()
        ..color = SafeHerColors.primaryRose.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Current User Location avatar along path
    // Approximate position along bezier
    final currentOffset = Offset(
      size.width * (0.25 + 0.53 * progress),
      size.height * (0.8 - 0.62 * progress),
    );

    // Pulse ring
    canvas.drawCircle(
      currentOffset,
      16,
      Paint()
        ..color = SafeHerColors.brightPink.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    // Outer border
    canvas.drawCircle(
      currentOffset,
      10,
      Paint()..color = Colors.white,
    );
    // Inner fill
    canvas.drawCircle(
      currentOffset,
      8,
      Paint()..color = SafeHerColors.primaryRose,
    );
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.showAlternative != showAlternative ||
      oldDelegate.isNightMode != isNightMode;
}

/// Radar Nearby Map Painter for Verified Safe Haven Network (Screen C2)
class RadarMapPainter extends CustomPainter {
  final double pulseValue;
  final int selectedPlaceIndex;

  RadarMapPainter({
    this.pulseValue = 0.5,
    this.selectedPlaceIndex = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.48);

    // Dark Map background
    final bgPaint = Paint()..color = const Color(0xFF1E262C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid/roads
    final roadPaint = Paint()
      ..color = const Color(0xFF2C3942)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), roadPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), roadPaint);
    canvas.drawLine(Offset(0, center.dy * 0.4), Offset(size.width, center.dy * 0.4), roadPaint);
    canvas.drawLine(Offset(0, center.dy * 1.5), Offset(size.width, center.dy * 1.5), roadPaint);

    // Concentric Radar Rings
    final ringRadii = [60.0, 110.0, 160.0, 210.0];
    for (int i = 0; i < ringRadii.length; i++) {
      final r = ringRadii[i] + (i == 1 ? pulseValue * 15 : 0);
      final ringPaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.15 - i * 0.02)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(center, r, ringPaint);
    }

    // Soft cyan radar sweep / glow fill
    final radarFill = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.18),
          const Color(0xFF2196F3).withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 140));
    canvas.drawCircle(center, 140, radarFill);

    // Place Markers around user
    // 1. Police (Blue)
    _drawMarker(canvas, Offset(center.dx - 80, center.dy + 70), const Color(0xFF2979FF), Icons.local_police);
    // 2. Hospital (Red/Magenta)
    _drawMarker(canvas, Offset(center.dx + 90, center.dy - 65), const Color(0xFFFF1744), Icons.local_hospital);
    // 3. Pharmacy (Amber/Orange)
    _drawMarker(canvas, Offset(center.dx + 115, center.dy + 60), const Color(0xFFFF9100), Icons.medical_services);
    // 4. Women Help Center (Pink)
    _drawMarker(canvas, Offset(center.dx - 95, center.dy - 50), SafeHerColors.brightPink, Icons.shield);
    // 5. Verified Safe Place (Green)
    _drawMarker(canvas, Offset(center.dx - 20, center.dy - 120), SafeHerColors.successGreen, Icons.verified_user);

    // User center marker
    canvas.drawCircle(
      center,
      18,
      Paint()..color = SafeHerColors.primaryRose.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      center,
      10,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()..color = SafeHerColors.primaryRose,
    );
  }

  void _drawMarker(Canvas canvas, Offset offset, Color color, IconData icon) {
    // Marker glow
    canvas.drawCircle(
      offset,
      14,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    // Pin head
    canvas.drawCircle(
      offset,
      10,
      Paint()..color = color,
    );
    // Center white dot
    canvas.drawCircle(
      offset,
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant RadarMapPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.selectedPlaceIndex != selectedPlaceIndex;
}
