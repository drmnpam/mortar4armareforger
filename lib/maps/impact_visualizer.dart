import 'dart:math';
import 'dart:ui';

import '../../models/models.dart';

/// Impact visualization calculations
/// Provides impact radius and spread ellipse for map display
class ImpactVisualizer {
  /// Standard mortar kill radius in meters
  static const double defaultKillRadius = 25.0;
  static const double defaultCasualtyRadius = 50.0;
  
  /// Calculate impact radius based on charge and distance
  /// Higher charges have larger dispersion
  static double calculateImpactRadius(
    double distance,
    int charge, {
    double baseRadius = defaultKillRadius,
  }) {
    // Dispersion increases with distance and charge
    final distanceFactor = 1 + (distance / 10000); // 0-100% increase
    final chargeFactor = 1 + (charge * 0.15); // 15% per charge level
    
    return baseRadius * distanceFactor * chargeFactor;
  }
  
  /// Calculate spread ellipse dimensions
  /// Returns (semiMajor, semiMinor, rotation) in meters/degrees
  static ({double semiMajor, double semiMinor, double rotation}) calculateSpreadEllipse(
    double distance,
    int charge,
    double? azimuth,
  ) {
    // Long axis is along the trajectory direction
    // Short axis is perpendicular
    
    final baseSemiMajor = calculateImpactRadius(distance, charge, baseRadius: 20);
    final baseSemiMinor = baseSemiMajor * 0.6; // Typical 1:0.6 ratio
    
    // Increase dispersion with range
    final rangeFactor = 1 + (distance / 8000);
    
    final semiMajor = baseSemiMajor * rangeFactor;
    final semiMinor = baseSemiMinor * rangeFactor;
    
    // Rotation follows azimuth
    final rotation = azimuth != null ? azimuth * (360 / 6400) : 0;
    
    return (semiMajor: semiMajor, semiMinor: semiMinor, rotation: rotation);
  }
  
  /// Convert ellipse dimensions from meters to pixels
  static ({double semiMajor, double semiMinor, double rotation}) metersToPixels(
    ({double semiMajor, double semiMinor, double rotation}) ellipse,
    double scale, // meters per pixel
  ) {
    return (
      semiMajor: ellipse.semiMajor / scale,
      semiMinor: ellipse.semiMinor / scale,
      rotation: ellipse.rotation,
    );
  }
  
  /// Get concentric circles for impact visualization
  static List<ImpactCircle> getImpactCircles(
    double distance,
    int charge,
  ) {
    return [
      ImpactCircle(
        radius: calculateImpactRadius(distance, charge, baseRadius: 15),
        color: const Color(0xFFEF5350), // Red - kill zone
        opacity: 0.3,
        label: 'KILL',
      ),
      ImpactCircle(
        radius: calculateImpactRadius(distance, charge, baseRadius: 30),
        color: const Color(0xFFFFA726), // Orange - casualty
        opacity: 0.2,
        label: 'CASUALTY',
      ),
      ImpactCircle(
        radius: calculateImpactRadius(distance, charge, baseRadius: 60),
        color: const Color(0xFFFFEB3B), // Yellow - suppression
        opacity: 0.15,
        label: 'SUPPRESSION',
      ),
    ];
  }
  
  /// Check if a point is within impact zone
  static bool isInImpactZone(
    Position point,
    Position impact,
    double distance,
    int charge, {
    ImpactZoneType zone = ImpactZoneType.casualty,
  }) {
    double radius;
    switch (zone) {
      case ImpactZoneType.kill:
        radius = calculateImpactRadius(distance, charge, baseRadius: 15);
        break;
      case ImpactZoneType.casualty:
        radius = calculateImpactRadius(distance, charge, baseRadius: 30);
        break;
      case ImpactZoneType.suppression:
        radius = calculateImpactRadius(distance, charge, baseRadius: 60);
        break;
    }
    
    final dx = point.x - impact.x;
    final dy = point.y - impact.y;
    final dist = (dx * dx + dy * dy);
    
    return dist <= radius * radius;
  }
  
  /// Calculate probability of hit within area
  static double calculateHitProbability(
    Position target,
    Position impact,
    double distance,
    int charge,
    double targetRadius,
  ) {
    final impactRadius = calculateImpactRadius(distance, charge);
    
    // Simplified probability model
    // Overlap of two circles divided by target area
    final dist = (target.x - impact.x) * (target.x - impact.x) +
                 (target.y - impact.y) * (target.y - impact.y);
    
    if (dist > (impactRadius + targetRadius) * (impactRadius + targetRadius)) {
      return 0.0;
    }
    
    if (dist < (impactRadius - targetRadius) * (impactRadius - targetRadius)) {
      return 1.0;
    }
    
    // Partial overlap - simplified calculation
    final overlap = (impactRadius + targetRadius) - dist;
    return (overlap / (2 * targetRadius)).clamp(0.0, 1.0);
  }
  
  /// Get CEP (Circular Error Probable) radius
  /// 50% of rounds fall within this radius
  static double getCEP(double distance, int charge) {
    // Approximate CEP formula
    // CEP increases with distance and charge
    final baseCEP = 10.0; // 10m at close range
    final distanceFactor = 1 + (distance / 5000);
    final chargeFactor = 1 + (charge * 0.2);
    
    return baseCEP * distanceFactor * chargeFactor;
  }
}

/// Impact circle for visualization
class ImpactCircle {
  final double radius;
  final Color color;
  final double opacity;
  final String label;
  
  const ImpactCircle({
    required this.radius,
    required this.color,
    required this.opacity,
    required this.label,
  });
}

enum ImpactZoneType {
  kill,
  casualty,
  suppression,
}

/// Canvas painter for impact visualization
class ImpactPainter extends CustomPainter {
  final Position impactPosition;
  final double distance;
  final int charge;
  final double scale; // meters per pixel
  final double? azimuth;
  final bool showEllipse;
  final bool showCircles;
  
  ImpactPainter({
    required this.impactPosition,
    required this.distance,
    required this.charge,
    required this.scale,
    this.azimuth,
    this.showEllipse = true,
    this.showCircles = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      impactPosition.x / scale,
      size.height - (impactPosition.y / scale),
    );
    
    if (showCircles) {
      _drawImpactCircles(canvas, center);
    }
    
    if (showEllipse && azimuth != null) {
      _drawSpreadEllipse(canvas, center);
    }
  }
  
  void _drawImpactCircles(Canvas canvas, Offset center) {
    final circles = ImpactVisualizer.getImpactCircles(distance, charge);
    
    for (final circle in circles.reversed) {
      final radiusPx = circle.radius / scale;
      
      final paint = Paint()
        ..color = circle.color.withOpacity(circle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radiusPx, paint);
      
      // Draw border
      final borderPaint = Paint()
        ..color = circle.color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(center, radiusPx, borderPaint);
    }
  }
  
  void _drawSpreadEllipse(Canvas canvas, Offset center) {
    final ellipse = ImpactVisualizer.calculateSpreadEllipse(distance, charge, azimuth);
    final pixelEllipse = ImpactVisualizer.metersToPixels(ellipse, scale);
    
    final rect = Rect.fromCenter(
      center: center,
      width: pixelEllipse.semiMajor * 2,
      height: pixelEllipse.semiMinor * 2,
    );
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pixelEllipse.rotation * pi / 180);
    canvas.translate(-center.dx, -center.dy);
    
    final paint = Paint()
      ..color = const Color(0xFFEF5350).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(rect, paint);
    
    final borderPaint = Paint()
      ..color = const Color(0xFFEF5350).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawOval(rect, borderPaint);
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Helper class for Rect
class Rect {
  final Offset center;
  final double width;
  final double height;
  
  Rect.fromCenter({required this.center, required this.width, required this.height});
}
