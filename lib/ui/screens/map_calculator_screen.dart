import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../maps/maps.dart';
import '../../maps/cubit/map_cubit.dart';
import '../../models/models.dart';
import '../widgets/firing_solution_card.dart';

class MapCalculatorScreen extends StatelessWidget {
  const MapCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('MAP CALCULATOR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Toggle grid',
            onPressed: () => context.read<MapCubit>().toggleGrid(),
          ),
          IconButton(
            icon: const Icon(Icons.straighten),
            tooltip: 'Toggle distance line',
            onPressed: () => context.read<MapCubit>().toggleDistanceLine(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => context.read<MapCubit>().loadMap(value),
            itemBuilder: (context) {
              final state = context.read<MapCubit>().state;
              return state.availableMaps.map((map) {
                return PopupMenuItem(
                  value: map,
                  child: Row(
                    children: [
                      if (map == state.selectedMap)
                        Icon(Icons.check, color: AppTheme.accent, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(map.toUpperCase()),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(state.error!, style: TextStyle(color: AppTheme.danger)),
                ],
              ),
            );
          }
          
          if (state.currentMetadata == null) {
            return const Center(
              child: Text('No map loaded'),
            );
          }

          return Stack(
            children: [
              // Map Canvas
              _MapCanvas(
                metadata: state.currentMetadata!,
                markers: state.markers,
                showGrid: state.showGrid,
                showDistanceLine: state.showDistanceLine,
                zoomLevel: state.zoomLevel,
                panX: state.panX,
                panY: state.panY,
              ),
              
              // Controls Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomPanel(
                  hasMortar: state.hasMortar,
                  hasTarget: state.hasTarget,
                  solution: state.solution,
                  selectedMortar: state.selectedMortar,
                  availableMortars: context.read<MapCubit>().availableMortars,
                  onMortarSelected: (type) => context.read<MapCubit>().setMortarType(type),
                  onAddMortar: () => _showAddMarkerDialog(context, MarkerType.mortar),
                  onAddTarget: () => _showAddMarkerDialog(context, MarkerType.target),
                  onClear: () => context.read<MapCubit>().clearMarkers(),
                ),
              ),
              
              // Zoom Controls
              Positioned(
                right: 16,
                top: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () => context.read<MapCubit>().setZoom(state.zoomLevel * 1.2),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () => context.read<MapCubit>().setZoom(state.zoomLevel / 1.2),
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddMarkerDialog(BuildContext context, MarkerType type) {
    final cubit = context.read<MapCubit>();
    final xController = TextEditingController();
    final yController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          type == MarkerType.mortar ? 'PLACE MORTAR' : 'PLACE TARGET',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xController,
              decoration: InputDecoration(
                labelText: 'X COORDINATE',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: yController,
              decoration: InputDecoration(
                labelText: 'Y COORDINATE',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final x = double.tryParse(xController.text) ?? 0;
              final y = double.tryParse(yController.text) ?? 0;
              final position = Position(x: x, y: y);
              
              if (type == MarkerType.mortar) {
                cubit.addMortar(position);
              } else {
                cubit.addTarget(position);
              }
              
              Navigator.pop(dialogContext);
            },
            child: const Text('PLACE'),
          ),
        ],
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final MapMetadata metadata;
  final List<MapMarker> markers;
  final bool showGrid;
  final bool showDistanceLine;
  final double zoomLevel;
  final double panX;
  final double panY;

  const _MapCanvas({
    required this.metadata,
    required this.markers,
    required this.showGrid,
    required this.showDistanceLine,
    required this.zoomLevel,
    required this.panX,
    required this.panY,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        context.read<MapCubit>().setPan(
          panX + details.delta.dx,
          panY + details.delta.dy,
        );
      },
      child: Container(
        color: AppTheme.background,
        child: CustomPaint(
          painter: _MapPainter(
            metadata: metadata,
            markers: markers,
            showGrid: showGrid,
            showDistanceLine: showDistanceLine,
            zoomLevel: zoomLevel,
            panX: panX,
            panY: panY,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final MapMetadata metadata;
  final List<MapMarker> markers;
  final bool showGrid;
  final bool showDistanceLine;
  final double zoomLevel;
  final double panX;
  final double panY;

  _MapPainter({
    required this.metadata,
    required this.markers,
    required this.showGrid,
    required this.showDistanceLine,
    required this.zoomLevel,
    required this.panX,
    required this.panY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size);
    }
    
    // Draw distance line if enabled and both markers exist
    if (showDistanceLine) {
      final mortar = markers.where((m) => m.type == MarkerType.mortar).firstOrNull;
      final target = markers.where((m) => m.type == MarkerType.target).firstOrNull;
      if (mortar != null && target != null) {
        _drawDistanceLine(canvas, size, mortar, target);
      }
    }
    
    // Draw markers
    for (final marker in markers) {
      _drawMarker(canvas, size, marker);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    final pixelsPerGrid = metadata.gridSize * metadata.pixelsPerMeter * zoomLevel;
    
    // Vertical lines
    double x = panX % pixelsPerGrid;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += pixelsPerGrid;
    }
    
    // Horizontal lines
    double y = panY % pixelsPerGrid;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += pixelsPerGrid;
    }
  }

  void _drawDistanceLine(Canvas canvas, Size size, MapMarker mortar, MapMarker target) {
    final mPos = _worldToScreen(mortar.position, size);
    final tPos = _worldToScreen(target.position, size);
    
    if (mPos == null || tPos == null) return;
    
    final paint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Dashed line effect
    final path = Path();
    path.moveTo(mPos.dx, mPos.dy);
    path.lineTo(tPos.dx, tPos.dy);
    
    canvas.drawPath(path, paint);
    
    // Draw distance label at midpoint
    final midX = (mPos.dx + tPos.dx) / 2;
    final midY = (mPos.dy + tPos.dy) / 2;
    
    final dx = target.position.x - mortar.position.x;
    final dy = target.position.y - mortar.position.y;
    final distance = (dx * dx + dy * dy);
    
    final textSpan = TextSpan(
      text: '${distance.toStringAsFixed(0)}m',
      style: TextStyle(
        color: AppTheme.accent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        backgroundColor: AppTheme.background.withOpacity(0.8),
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - 20));
  }

  void _drawMarker(Canvas canvas, Size size, MapMarker marker) {
    final pos = _worldToScreen(marker.position, size);
    if (pos == null) return;
    
    final size_px = marker.size * zoomLevel;
    
    // Draw marker circle
    final paint = Paint()
      ..color = marker.color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(pos, size_px / 2, paint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(pos, size_px / 2, borderPaint);
    
    // Draw label if space permits
    if (zoomLevel > 0.5) {
      final textSpan = TextSpan(
        text: marker.label ?? '',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 10 * zoomLevel,
          fontWeight: FontWeight.bold,
          backgroundColor: AppTheme.background.withOpacity(0.8),
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy + size_px / 2 + 4),
      );
    }
  }

  Offset? _worldToScreen(Position position, Size size) {
    final pixelX = position.x * metadata.pixelsPerMeter * zoomLevel + panX;
    final pixelY = (metadata.worldSize * metadata.pixelsPerMeter - 
                   position.y * metadata.pixelsPerMeter) * zoomLevel + panY;
    return Offset(pixelX, pixelY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BottomPanel extends StatelessWidget {
  final bool hasMortar;
  final bool hasTarget;
  final FiringSolution? solution;
  final String selectedMortar;
  final List<String> availableMortars;
  final Function(String) onMortarSelected;
  final VoidCallback onAddMortar;
  final VoidCallback onAddTarget;
  final VoidCallback onClear;

  const _BottomPanel({
    required this.hasMortar,
    required this.hasTarget,
    this.solution,
    required this.selectedMortar,
    required this.availableMortars,
    required this.onMortarSelected,
    required this.onAddMortar,
    required this.onAddTarget,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mortar selector and action buttons
              Row(
                children: [
                  // Mortar type dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMortar,
                        dropdownColor: AppTheme.surfaceLight,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.accent),
                        items: availableMortars.map((mortar) {
                          return DropdownMenuItem(
                            value: mortar,
                            child: Text(mortar),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) onMortarSelected(value);
                        },
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  if (!hasMortar)
                    ElevatedButton.icon(
                      onPressed: onAddMortar,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('MORTAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    )
                  else if (!hasTarget)
                    ElevatedButton.icon(
                      onPressed: onAddTarget,
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('TARGET'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    )
                  else ...[
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Clear markers',
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Firing solution display
              if (solution != null)
                FiringSolutionCard(solution: solution!)
              else if (hasMortar && hasTarget)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Calculating...',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasMortar
                              ? 'Place target marker to calculate solution'
                              : 'Place mortar marker to begin',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
