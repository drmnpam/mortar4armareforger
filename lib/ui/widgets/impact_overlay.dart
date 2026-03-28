import 'package:flutter/material.dart';
import 'dart:math';
import '../../app/theme/app_theme.dart';
import '../../maps/advanced_maps.dart';
import '../../models/models.dart';

/// Map overlay showing impact circles and spread ellipse
class ImpactOverlay extends StatelessWidget {
  final Position impactPosition;
  final FiringSolution? solution;
  final Size mapSize;
  final double worldSize;
  final double zoom;
  final Offset pan;
  final bool showCircles;
  final bool showEllipse;

  const ImpactOverlay({
    super.key,
    required this.impactPosition,
    this.solution,
    required this.mapSize,
    required this.worldSize,
    required this.zoom,
    required this.pan,
    this.showCircles = true,
    this.showEllipse = true,
  });

  @override
  Widget build(BuildContext context) {
    if (solution == null) return const SizedBox.shrink();

    final scale = worldSize / mapSize.width;

    return CustomPaint(
      size: mapSize,
      painter: _ImpactOverlayPainter(
        impact: impactPosition,
        solution: solution!,
        scale: scale,
        zoom: zoom,
        pan: pan,
        showCircles: showCircles,
        showEllipse: showEllipse,
      ),
    );
  }
}

class _ImpactOverlayPainter extends CustomPainter {
  final Position impact;
  final FiringSolution solution;
  final double scale;
  final double zoom;
  final Offset pan;
  final bool showCircles;
  final bool showEllipse;

  _ImpactOverlayPainter({
    required this.impact,
    required this.solution,
    required this.scale,
    required this.zoom,
    required this.pan,
    required this.showCircles,
    required this.showEllipse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert impact position to pixel coordinates
    final impactPixel = _worldToScreen(impact, size);

    if (showCircles) {
      _drawImpactCircles(canvas, impactPixel);
    }

    if (showEllipse) {
      _drawSpreadEllipse(canvas, impactPixel);
    }

    // Draw impact marker
    _drawImpactMarker(canvas, impactPixel);
  }

  void _drawImpactCircles(Canvas canvas, Offset center) {
    final circles = ImpactVisualizer.getImpactCircles(
      solution.distance,
      solution.charge,
    );

    for (final circle in circles.reversed) {
      final radiusPx = (circle.radius / scale) * zoom;

      // Fill
      final fillPaint = Paint()
        ..color = circle.color.withOpacity(circle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radiusPx, fillPaint);

      // Border
      final borderPaint = Paint()
        ..color = circle.color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radiusPx, borderPaint);

      // Label (only for largest circle)
      if (circle.label == 'SUPPRESSION') {
        _drawCircleLabel(canvas, center, radiusPx, circle.label);
      }
    }
  }

  void _drawSpreadEllipse(Canvas canvas, Offset center) {
    final ellipse = ImpactVisualizer.calculateSpreadEllipse(
      solution.distance,
      solution.charge,
      solution.azimuth,
    );

    final semiMajorPx = (ellipse.semiMajor / scale) * zoom;
    final semiMinorPx = (ellipse.semiMinor / scale) * zoom;
    final rotationRad = ellipse.rotation * (pi / 180);

    // Save canvas state
    canvas.save();

    // Translate to center, rotate, then translate back
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationRad);
    canvas.translate(-center.dx, -center.dy);

    // Draw ellipse
    final rect = Rect.fromCenter(
      center: center,
      width: semiMajorPx * 2,
      height: semiMinorPx * 2,
    );

    // Fill
    final fillPaint = Paint()
      ..color = const Color(0xFFEF5350).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawOval(rect, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFEF5350).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(rect, borderPaint);

    // Draw major axis line
    final axisPaint = Paint()
      ..color = const Color(0xFFEF5350).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeDash = [5, 5];

    canvas.drawLine(
      Offset(center.dx - semiMajorPx, center.dy),
      Offset(center.dx + semiMajorPx, center.dy),
      axisPaint,
    );

    canvas.restore();
  }

  void _drawImpactMarker(Canvas canvas, Offset center) {
    // Outer glow
    final glowPaint = Paint()
      ..color = AppTheme.danger.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 15, glowPaint);

    // Inner marker
    final markerPaint = Paint()
      ..color = AppTheme.danger
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, markerPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 8, borderPaint);

    // Crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx + 12, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      crossPaint,
    );
  }

  void _drawCircleLabel(Canvas canvas, Offset center, double radius, String label) {
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 4,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - radius - 20,
      ),
    );
  }

  Offset _worldToScreen(Position pos, Size size) {
    final pixelX = (pos.x / scale) * zoom + pan.dx;
    final pixelY = (size.height - (pos.y / scale)) * zoom + pan.dy;
    return Offset(pixelX, pixelY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Legend for impact overlay
class ImpactLegend extends StatelessWidget {
  const ImpactLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'IMPACT ZONES',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _LegendItem(color: const Color(0xFFEF5350), label: 'KILL'),
          const SizedBox(height: 4),
          _LegendItem(color: const Color(0xFFFFA726), label: 'CASUALTY'),
          const SizedBox(height: 4),
          _LegendItem(color: const Color(0xFFFFEB3B), label: 'SUPPRESSION'),
          const SizedBox(height: 4),
          _LegendItem(
            color: const Color(0xFFEF5350),
            label: 'SPREAD',
            isDashed: true,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(
              color: color,
              width: 1.5,
              style: isDashed ? BorderStyle.none : BorderStyle.solid,
            ),
            borderRadius: isDashed ? BorderRadius.circular(6) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
