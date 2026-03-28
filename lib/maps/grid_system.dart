import '../../models/models.dart';

/// Arma Reforger compatible grid coordinate system
/// 
/// Arma uses a grid reference system where:
/// - World coordinates are in meters (x, y)
/// - Grid references are displayed as: 012 345 (6-digit precision)
///   or 0123 4567 (8-digit precision)
/// - Grid lines are typically every 100m
/// - Map labels use letter combinations (AA, AB, etc.)
class GridCoordinateSystem {
  /// Grid cell size in meters (typically 100m in Arma)
  final double gridSize;
  
  /// World size in meters
  final double worldSize;
  
  /// Number of digits in grid reference (6 or 8)
  final int precision;
  
  const GridCoordinateSystem({
    this.gridSize = 100.0,
    required this.worldSize,
    this.precision = 6,
  });
  
  /// Convert world coordinates (meters) to grid reference
  /// Returns formatted string like "012 345"
  String worldToGrid(Position position) {
    final digits = precision ~/ 2;
    
    // Scale to appropriate precision
    final scale = worldSize / (10 * digits);
    
    final xInt = (position.x / scale).floor();
    final yInt = (position.y / scale).floor();
    
    final xStr = xInt.toString().padLeft(digits, '0');
    final yStr = yInt.toString().padLeft(digits, '0');
    
    return '$xStr $yStr';
  }
  
  /// Parse grid reference to world coordinates
  /// Input: "012 345" or "0123 4567"
  Position gridToWorld(String gridReference) {
    // Remove spaces and dashes
    final clean = gridReference.replaceAll(RegExp(r'[\s\-]'), '');
    
    if (clean.length != precision) {
      throw FormatException('Invalid grid reference format: $gridReference');
    }
    
    final digits = precision ~/ 2;
    final scale = worldSize / (10 * digits);
    
    final xStr = clean.substring(0, digits);
    final yStr = clean.substring(digits);
    
    final x = int.parse(xStr) * scale + (scale / 2); // Center of grid square
    final y = int.parse(yStr) * scale + (scale / 2);
    
    return Position(x: x, y: y);
  }
  
  /// Get grid cell coordinates from world position
  /// Returns (col, row) indices
  ({int col, int row}) worldToGridCell(Position position) {
    final col = (position.x / gridSize).floor();
    final row = (position.y / gridSize).floor();
    return (col: col, row: row);
  }
  
  /// Get world coordinates of grid cell center
  Position gridCellToWorld(int col, int row) {
    return Position(
      x: col * gridSize + gridSize / 2,
      y: row * gridSize + gridSize / 2,
    );
  }
  
  /// Get grid cell bounds in world coordinates
  GridCellBounds getGridCellBounds(int col, int row) {
    return GridCellBounds(
      minX: col * gridSize,
      minY: row * gridSize,
      maxX: (col + 1) * gridSize,
      maxY: (row + 1) * gridSize,
      center: Position(
        x: col * gridSize + gridSize / 2,
        y: row * gridSize + gridSize / 2,
      ),
    );
  }
  
  /// Get grid label (AA, AB, etc.)
  /// Arma uses a letter-based grid system
  String getGridLabel(int col, int row) {
    final letter1 = _getGridLetter(col ~/ 26);
    final letter2 = _getGridLetter(col % 26);
    final num1 = (row ~/ 26).toString().padLeft(2, '0');
    final num2 = (row % 26).toString().padLeft(2, '0');
    
    return '$letter1$letter2 $num1$num2';
  }
  
  /// Convert column index to letter
  String _getGridLetter(int index) {
    return String.fromCharCode(65 + (index % 26));
  }
  
  /// Parse grid label to cell coordinates
  /// Input: "AA 0001" or "AB 0102"
  ({int col, int row})? parseGridLabel(String label) {
    try {
      final parts = label.trim().split(' ');
      if (parts.length != 2) return null;
      
      final letters = parts[0];
      final numbers = parts[1];
      
      if (letters.length != 2 || numbers.length != 4) return null;
      
      final col = (letters[0].codeUnitAt(0) - 65) * 26 +
                  (letters[1].codeUnitAt(0) - 65);
      final row = int.parse(numbers.substring(0, 2)) * 26 +
                  int.parse(numbers.substring(2));
      
      return (col: col, row: row);
    } catch (e) {
      return null;
    }
  }
  
  /// Format coordinates for quick entry (6-digit)
  /// Always returns format: XXX YYY
  String formatQuickEntry(double x, double y) {
    final xInt = (x / 100).floor();
    final yInt = (y / 100).floor();
    
    final xStr = xInt.toString().padLeft(3, '0');
    final yStr = yInt.toString().padLeft(3, '0');
    
    return '$xStr $yStr';
  }
  
  /// Parse quick entry to position
  Position parseQuickEntry(String input) {
    final clean = input.replaceAll(RegExp(r'[^\d]'), '');
    
    if (clean.length != 6) {
      throw FormatException('Quick entry must be 6 digits');
    }
    
    final x = int.parse(clean.substring(0, 3)) * 100 + 50;
    final y = int.parse(clean.substring(3)) * 100 + 50;
    
    return Position(x: x.toDouble(), y: y.toDouble());
  }
  
  /// Get grid line positions for drawing
  /// Returns list of vertical and horizontal line positions in meters
  GridLines getGridLines() {
    final vertical = <double>[];
    final horizontal = <double>[];
    
    for (double x = 0; x <= worldSize; x += gridSize) {
      vertical.add(x);
    }
    
    for (double y = 0; y <= worldSize; y += gridSize) {
      horizontal.add(y);
    }
    
    return GridLines(
      vertical: vertical,
      horizontal: horizontal,
      labels: _generateGridLabels(vertical, horizontal),
    );
  }
  
  Map<double, String> _generateGridLabels(
    List<double> vertical,
    List<double> horizontal,
  ) {
    final labels = <double, String>{};
    
    // Label every 10th line
    for (int i = 0; i < vertical.length; i += 10) {
      labels[vertical[i]] = (i * 100).toString();
    }
    
    for (int i = 0; i < horizontal.length; i += 10) {
      labels[horizontal[i]] = (i * 100).toString();
    }
    
    return labels;
  }
  
  /// Validate grid reference
  bool isValidGrid(String gridReference) {
    try {
      final clean = gridReference.replaceAll(RegExp(r'[\s\-]'), '');
      return clean.length == precision && int.tryParse(clean) != null;
    } catch (e) {
      return false;
    }
  }
}

/// Bounds of a grid cell
class GridCellBounds {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final Position center;
  
  const GridCellBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.center,
  });
  
  double get width => maxX - minX;
  double get height => maxY - minY;
  
  bool contains(Position position) {
    return position.x >= minX && position.x <= maxX &&
           position.y >= minY && position.y <= maxY;
  }
}

/// Grid line information for rendering
class GridLines {
  final List<double> vertical;
  final List<double> horizontal;
  final Map<double, String> labels;
  
  const GridLines({
    required this.vertical,
    required this.horizontal,
    required this.labels,
  });
}
