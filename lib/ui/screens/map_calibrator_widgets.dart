import 'package:flutter/material.dart';

// Calibration UI Widgets

class _CalibrationPointMarker extends StatelessWidget {
  final String label;
  final Color color;

  const _CalibrationPointMarker({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Crosshair extends StatelessWidget {
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
