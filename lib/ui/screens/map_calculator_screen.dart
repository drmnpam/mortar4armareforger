import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../maps/cubit/map_cubit.dart';
import '../../maps/maps.dart';
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

          if (state.error != null && state.currentMetadata == null) {
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
            return const Center(child: Text('No map loaded'));
          }

          return Stack(
            children: [
              _MapCanvas(
                metadata: state.currentMetadata!,
                mapImagePath: state.mapImagePath,
                markers: state.markers,
                showGrid: state.showGrid,
                showDistanceLine: state.showDistanceLine,
                zoomLevel: state.zoomLevel,
                panX: state.panX,
                panY: state.panY,
                hasMortar: state.hasMortar,
                hasTarget: state.hasTarget,
                onTapPosition: (position) => _handleTap(context, state, position),
                onLongPressPosition: (position) {
                  context.read<MapCubit>().addMortar(position);
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomPanel(
                  hasMortar: state.hasMortar,
                  hasTarget: state.hasTarget,
                  error: state.error,
                  solution: state.solution,
                  selectedMortar: state.selectedMortar,
                  availableMortars: context.read<MapCubit>().availableMortars,
                  onMortarSelected: (type) => context.read<MapCubit>().setMortarType(type),
                  onClear: () => context.read<MapCubit>().clearMarkers(),
                ),
              ),
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

  void _handleTap(BuildContext context, MapState state, Position position) {
    final cubit = context.read<MapCubit>();

    if (!state.hasMortar) {
      cubit.addMortar(position);
      return;
    }

    cubit.addTarget(position);
  }
}

class _MapCanvas extends StatelessWidget {
  final MapMetadata metadata;
  final String? mapImagePath;
  final List<MapMarker> markers;
  final bool showGrid;
  final bool showDistanceLine;
  final double zoomLevel;
  final double panX;
  final double panY;
  final bool hasMortar;
  final bool hasTarget;
  final ValueChanged<Position> onTapPosition;
  final ValueChanged<Position> onLongPressPosition;

  const _MapCanvas({
    required this.metadata,
    required this.mapImagePath,
    required this.markers,
    required this.showGrid,
    required this.showDistanceLine,
    required this.zoomLevel,
    required this.panX,
    required this.panY,
    required this.hasMortar,
    required this.hasTarget,
    required this.onTapPosition,
    required this.onLongPressPosition,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = constraints.biggest.shortestSide;
        final mapOriginX = (constraints.maxWidth - mapSize) / 2;
        final mapOriginY = (constraints.maxHeight - mapSize) / 2;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final world = _screenToWorld(
              screenPosition: details.localPosition,
              mapSize: mapSize,
              mapOriginX: mapOriginX,
              mapOriginY: mapOriginY,
            );
            if (world != null) {
              onTapPosition(world);
            }
          },
          onLongPressStart: (details) {
            final world = _screenToWorld(
              screenPosition: details.localPosition,
              mapSize: mapSize,
              mapOriginX: mapOriginX,
              mapOriginY: mapOriginY,
            );
            if (world != null) {
              onLongPressPosition(world);
            }
          },
          onPanUpdate: (details) {
            context.read<MapCubit>().setPan(
                  panX + details.delta.dx,
                  panY + details.delta.dy,
                );
          },
          child: Container(
            color: AppTheme.background,
            child: ClipRect(
              child: Stack(
                children: [
                  Transform(
                    transform: Matrix4.identity()
                      ..translate(mapOriginX + panX, mapOriginY + panY)
                      ..scale(zoomLevel),
                    child: SizedBox(
                      width: mapSize,
                      height: mapSize,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: mapImagePath == null
                                ? Container(color: AppTheme.surfaceLight)
                                : Image.asset(
                                    mapImagePath!,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (context, _, __) {
                                      return Container(
                                        color: AppTheme.surfaceLight,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Map image unavailable',
                                          style: TextStyle(color: AppTheme.textSecondary),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MapOverlayPainter(
                                metadata: metadata,
                                markers: markers,
                                showGrid: showGrid,
                                showDistanceLine: showDistanceLine,
                                zoomLevel: zoomLevel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _TapHint(hasMortar: hasMortar, hasTarget: hasTarget),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Position? _screenToWorld({
    required Offset screenPosition,
    required double mapSize,
    required double mapOriginX,
    required double mapOriginY,
  }) {
    final localX = (screenPosition.dx - mapOriginX - panX) / zoomLevel;
    final localY = (screenPosition.dy - mapOriginY - panY) / zoomLevel;

    if (localX < 0 || localY < 0 || localX > mapSize || localY > mapSize) {
      return null;
    }

    final worldX = (localX / mapSize) * metadata.worldSize;
    final worldY = ((mapSize - localY) / mapSize) * metadata.worldSize;
    return Position(x: worldX, y: worldY);
  }
}

class _MapOverlayPainter extends CustomPainter {
  final MapMetadata metadata;
  final List<MapMarker> markers;
  final bool showGrid;
  final bool showDistanceLine;
  final double zoomLevel;

  _MapOverlayPainter({
    required this.metadata,
    required this.markers,
    required this.showGrid,
    required this.showDistanceLine,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    if (showDistanceLine) {
      final mortar = _findMarker(MarkerType.mortar);
      final target = _findMarker(MarkerType.target);
      if (mortar != null && target != null) {
        _drawDistanceLine(canvas, size, mortar, target);
      }
    }

    for (final marker in markers) {
      _drawMarker(canvas, size, marker);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gridLine.withOpacity(0.35)
      ..strokeWidth = 0.6;

    final pixelsPerGrid = (metadata.gridSize / metadata.worldSize) * size.width;

    for (double x = 0; x <= size.width; x += pixelsPerGrid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += pixelsPerGrid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDistanceLine(Canvas canvas, Size size, MapMarker mortar, MapMarker target) {
    final mPos = _worldToPixel(mortar.position, size);
    final tPos = _worldToPixel(target.position, size);
    final safeZoom = zoomLevel.clamp(0.25, 5.0);

    final paint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 1.5 / math.sqrt(safeZoom)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(mPos, tPos, paint);

    final distance = math.sqrt(
      math.pow(target.position.x - mortar.position.x, 2) +
          math.pow(target.position.y - mortar.position.y, 2),
    );

    final mid = Offset((mPos.dx + tPos.dx) / 2, (mPos.dy + tPos.dy) / 2);
    final textSpan = TextSpan(
      text: '${distance.toStringAsFixed(0)}m',
      style: TextStyle(
        color: AppTheme.accent,
        fontSize: 10 / math.sqrt(safeZoom),
        fontWeight: FontWeight.bold,
        backgroundColor: AppTheme.background.withOpacity(0.8),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(mid.dx - textPainter.width / 2, mid.dy - 20));
  }

  void _drawMarker(Canvas canvas, Size size, MapMarker marker) {
    final position = _worldToPixel(marker.position, size);
    final safeZoom = zoomLevel.clamp(0.25, 5.0);
    final baseRadius = marker.type == MarkerType.mortar || marker.type == MarkerType.target
        ? 6.0
        : 4.5;
    // Painter is drawn inside scaled map transform, so we compensate by sqrt(zoom)
    // to keep markers readable and avoid oversized circles on higher zoom levels.
    final radius = baseRadius / math.sqrt(safeZoom);

    final fillPaint = Paint()
      ..color = marker.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, radius, fillPaint);

    final borderPaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, radius, borderPaint);

    final textSpan = TextSpan(
      text: marker.label ?? '',
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 8 / math.sqrt(safeZoom),
        fontWeight: FontWeight.w700,
        backgroundColor: AppTheme.background.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy + radius + 4),
    );
  }

  Offset _worldToPixel(Position position, Size size) {
    final x = (position.x / metadata.worldSize) * size.width;
    final y = (1 - (position.y / metadata.worldSize)) * size.height;
    return Offset(x, y);
  }

  MapMarker? _findMarker(MarkerType type) {
    for (final marker in markers) {
      if (marker.type == type) {
        return marker;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _MapOverlayPainter oldDelegate) {
    return oldDelegate.metadata != metadata ||
        oldDelegate.markers != markers ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showDistanceLine != showDistanceLine ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}

class _TapHint extends StatelessWidget {
  final bool hasMortar;
  final bool hasTarget;

  const _TapHint({
    required this.hasMortar,
    required this.hasTarget,
  });

  @override
  Widget build(BuildContext context) {
    final message = !hasMortar
        ? 'Tap map to place mortar'
        : !hasTarget
            ? 'Tap map to place target'
            : 'Tap map to move target. Long press to move mortar';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.touch_app, size: 18, color: AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final bool hasMortar;
  final bool hasTarget;
  final String? error;
  final FiringSolution? solution;
  final String selectedMortar;
  final List<String> availableMortars;
  final ValueChanged<String> onMortarSelected;
  final VoidCallback onClear;

  const _BottomPanel({
    required this.hasMortar,
    required this.hasTarget,
    this.error,
    this.solution,
    required this.selectedMortar,
    required this.availableMortars,
    required this.onMortarSelected,
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
              Row(
                children: [
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
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.accent),
                        items: availableMortars.map((mortar) {
                          return DropdownMenuItem(
                            value: mortar,
                            child: Text(mortar),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onMortarSelected(value);
                          }
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear markers',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (solution != null)
                FiringSolutionCard(solution: solution!)
              else if (error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error!,
                          style: TextStyle(color: AppTheme.danger),
                        ),
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
                      Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          !hasMortar
                              ? 'Tap map to place mortar'
                              : !hasTarget
                                  ? 'Tap map to place target'
                                  : 'Calculating...',
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
