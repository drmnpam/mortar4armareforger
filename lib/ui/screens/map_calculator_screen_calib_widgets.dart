import 'package:flutter/material.dart';
import '../../models/models.dart';

// Calibration UI Widgets

class CalibrationPointMarker extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const CalibrationPointMarker({
    required this.label,
    required this.color,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class Crosshair extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Positioned(
            top: 19,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Colors.red),
          ),
          Positioned(
            left: 19,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: Colors.red),
          ),
          Positioned(
            top: 17,
            left: 17,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple magnifier showing zoomed area without full image
class MagnifierGlass extends StatelessWidget {
  final Offset position;

  const MagnifierGlass({
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    const double magnifierSize = 80;

    return Container(
      width: magnifierSize,
      height: magnifierSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.yellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        color: Colors.black87,
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // Grid background
            Container(
              color: Colors.grey[850],
              child: CustomPaint(
                size: const Size(magnifierSize, magnifierSize),
                painter: _MagnifierGridPainter(),
              ),
            ),
            // Bright crosshair in center
            Center(
              child: Container(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      top: 11,
                      left: 0,
                      right: 0,
                      child: Container(height: 2, color: Colors.yellowAccent),
                    ),
                    Positioned(
                      left: 11,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: Colors.yellowAccent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MagnifierGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
