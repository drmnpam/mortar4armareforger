import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../ballistics/ballistics.dart';
import '../../maps/cubit/map_cubit.dart';
import '../../maps/maps.dart';
import '../../models/models.dart';
import '../../weapons/weapon_registry.dart';
import '../widgets/firing_solution_card.dart';
import 'map_calculator_screen_calib_widgets.dart';

class MapCalculatorScreen extends StatefulWidget {
  const MapCalculatorScreen({super.key});

  @override
  State<MapCalculatorScreen> createState() => _MapCalculatorScreenState();
}

class _MapCalculatorScreenState extends State<MapCalculatorScreen> {
  bool _calibrationMode = false;

  Future<void> _openCalibrationDialog(
      BuildContext context, MapState state) async {
    if (mounted) {
      setState(() => _calibrationMode = true);
    }
    // Start new calibration flow
    context.read<MapCubit>().startCalibration();
    
    // Reset calibration mode when calibration ends
    final cubit = context.read<MapCubit>();
    await for (final newState in cubit.stream) {
      if (!newState.isCalibrating && mounted) {
        setState(() => _calibrationMode = false);
        break;
      }
    }
  }

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
            icon: const Icon(Icons.more_vert),
            tooltip: 'Map menu',
            onSelected: (value) {
              if (value == '__calibrate__') {
                context.read<MapCubit>().startCalibration();
                return;
              }
              if (value == '__add_map__') {
                _showAddCustomMapDialog(context);
                return;
              }
              if (value.startsWith('__map__:')) {
                context.read<MapCubit>().loadMap(value.substring(8));
              }
            },
            itemBuilder: (context) {
              final state = context.read<MapCubit>().state;
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem(
                  value: '__calibrate__',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.tune),
                    title: Text('Grid calibration'),
                  ),
                ),
                const PopupMenuItem(
                  value: '__add_map__',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add_photo_alternate_outlined),
                    title: Text('Add custom map'),
                  ),
                ),
                const PopupMenuDivider(),
              ];

              items.addAll(
                state.availableMaps.map((map) {
                  return PopupMenuItem(
                    value: '__map__:$map',
                    child: Row(
                      children: [
                        if (map == state.selectedMap)
                          Icon(Icons.check, color: AppTheme.accent, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            map.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
              return items;
            },
          ),
        ],
      ),
      body: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          try {
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
                  selectedWeapon: state.selectedWeapon,
                  onTapPosition: (position) =>
                      _handleTap(context, state, position),
                  onLongPressPosition: (position) {
                    _handleLongPress(context, state, position);
                  },
                  onViewChanged: (zoom, panX, panY) {
                    context.read<MapCubit>().setView(
                          zoom: zoom,
                          panX: panX,
                          panY: panY,
                          persist: true,
                        );
                  },
                  calibrationOffsetX: state.calibrationOffsetX,
                  calibrationOffsetY: state.calibrationOffsetY,
                  calibrationScaleX: state.calibrationScaleX,
                  calibrationScaleY: state.calibrationScaleY,
                  calibrationMode: _calibrationMode,
                  isCalibrating: state.isCalibrating,
                  calibrationStep: state.calibrationStep,
                  calibPointA: state.calibPointA,
                  calibPointB: state.calibPointB,
                  isDraggingCalibration: state.isDraggingCalibration,
                  dragPosition: state.dragPosition,
                  // Legacy callbacks - keep for compatibility
                  onCalibrationDragStart: (offset) {},
                  onCalibrationDragUpdate: (offset) {},
                  onCalibrationDragEnd: (position) {},
                  // New callbacks
                  onCalibrationPlacePoint: (position) {
                    context.read<MapCubit>().placeCalibrationPoint(position);
                  },
                  onCalibrationAdjustStart: (screenPos, zoom) {
                    context.read<MapCubit>().calibrationAdjustStart(screenPos, zoom);
                  },
                  onCalibrationAdjustUpdate: (screenPos, zoom) {
                    context.read<MapCubit>().calibrationAdjustUpdate(screenPos, zoom);
                  },
                  onCalibrationAdjustEnd: () {
                    context.read<MapCubit>().calibrationAdjustEnd();
                  },
                ),
                if (state.isCalibrating)
                  _buildCalibrationOverlay(context, state),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomPanel(
                    hasMortar: state.hasMortar,
                    hasTarget: state.hasTarget,
                    error: state.error,
                    solution: state.solution,
                    selectedWeapon: state.selectedWeapon,
                    availableWeapons: state.availableWeapons,
                    onWeaponSelected: (weapon) =>
                        context.read<MapCubit>().setWeapon(weapon ?? ''),
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
                        onPressed: () => context.read<MapCubit>().setView(
                              zoom: state.zoomLevel * 1.2,
                              panX: state.panX,
                              panY: state.panY,
                              persist: true,
                            ),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        onPressed: () => context.read<MapCubit>().setView(
                              zoom: state.zoomLevel / 1.2,
                              panX: state.panX,
                              panY: state.panY,
                              persist: true,
                            ),
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } catch (e, stackTrace) {
            debugPrint('=== BLOC BUILDER CRASH ===');
            debugPrint('Error: $e');
            debugPrint('Stack: $stackTrace');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text('Screen Error', style: TextStyle(color: Colors.white, fontSize: 20)),
                  Text('$e', style: TextStyle(color: Colors.red[300])),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildCalibrationOverlay(BuildContext context, MapState state) {
    final cubit = context.read<MapCubit>();
    
    String instruction;
    String actionButton;
    if (state.calibrationStep == 0) {
      instruction = 'TAP map to place START point of 100m line';
      actionButton = 'CANCEL';
    } else if (state.calibrationStep == 1) {
      instruction = 'TAP map to place END point (100m from start)';
      actionButton = 'RESET';
    } else if (state.calibrationStep == 2) {
      instruction = 'LONG PRESS and DRAG to adjust points. Tap APPLY when ready.';
      actionButton = 'RESET';
    } else {
      instruction = 'Calibration complete';
      actionButton = 'RESET';
    }

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, color: AppTheme.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GRID CALIBRATION',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              instruction,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.calibPointA != null && state.calibPointB != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Distance: ${_calculateDistance(state.calibPointA!, state.calibPointB!).toStringAsFixed(1)}m',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Target: 100m',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (state.calibrationStep == 0) {
                        cubit.cancelCalibration();
                      } else {
                        cubit.resetCalibrationNew();
                      }
                    },
                    child: Text(actionButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      cubit.cancelCalibration();
                    },
                    child: const Text('CLOSE'),
                  ),
                ),
                if (state.calibrationStep == 2) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        cubit.applyCalibration();
                      },
                      child: const Text('APPLY'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(Position a, Position b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _handleTap(BuildContext context, MapState state, Position position) {
    final cubit = context.read<MapCubit>();

    // Don't place mortar/target during calibration
    if (state.isCalibrating) {
      return;
    }

    if (!state.hasMortar) {
      cubit.addMortar(position);
      return;
    }

    cubit.addTarget(position);
  }

  void _handleLongPress(BuildContext context, MapState state, Position position) {
    final cubit = context.read<MapCubit>();

    // Move mortar on long press (calibration is now handled by new callbacks)
    if (state.hasMortar) {
      cubit.moveMortar(position);
    }
  }

  Future<void> _showAddCustomMapDialog(BuildContext context) async {
    final cubit = context.read<MapCubit>();
    final nameController = TextEditingController();
    final worldSizeController = TextEditingController(text: '10240');
    String? imagePath;
    String? localError;
    var isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                final path = result?.files.single.path;
                if (path == null || path.isEmpty) {
                  return;
                }
                setDialogState(() {
                  imagePath = path;
                  localError = null;
                });
              } catch (e) {
                setDialogState(() {
                  localError = 'Failed to open file picker: $e';
                });
              }
            }

            Future<void> submit() async {
              final name = nameController.text.trim();
              final parsedWorld =
                  double.tryParse(worldSizeController.text.trim());
              if (name.isEmpty || imagePath == null) {
                setDialogState(() {
                  localError = 'Enter map name and choose image';
                });
                return;
              }
              if (parsedWorld == null || parsedWorld <= 0) {
                setDialogState(() {
                  localError = 'World size must be a positive number';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                localError = null;
              });

              final ok = await cubit.addCustomMap(
                name: name,
                imagePath: imagePath!,
                worldSize: parsedWorld,
              );

              if (ok && dialogContext.mounted) {
                Navigator.pop(dialogContext);
                return;
              }

              setDialogState(() {
                isSaving = false;
                localError = cubit.state.error ?? 'Failed to add map';
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text(
                'ADD CUSTOM MAP',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Map name',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: worldSizeController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'World size (meters)',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            imagePath == null
                                ? 'No image selected'
                                : imagePath!.split(RegExp(r'[\\/]')).last,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: isSaving ? null : pickImage,
                          child: const Text('CHOOSE IMAGE'),
                        ),
                      ],
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localError!,
                          style: TextStyle(color: AppTheme.danger),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: Text(isSaving ? 'ADDING...' : 'ADD MAP'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    worldSizeController.dispose();
  }
}

class _MapCanvas extends StatefulWidget {
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
  final String selectedWeapon;
  final ValueChanged<Position> onTapPosition;
  final ValueChanged<Position> onLongPressPosition;
  final void Function(double zoom, double panX, double panY) onViewChanged;
  final double calibrationOffsetX;
  final double calibrationOffsetY;
  final double calibrationScaleX;
  final double calibrationScaleY;
  final bool calibrationMode;
  // New calibration drag state
  final bool isCalibrating;
  final int? calibrationStep;
  final Position? calibPointA;
  final Position? calibPointB;
  final bool isDraggingCalibration;
  final Offset? dragPosition;
  // Legacy callbacks (for old drag approach)
  final Function(Offset) onCalibrationDragStart;
  final Function(Offset) onCalibrationDragUpdate;
  final Function(Position) onCalibrationDragEnd;
  // New callbacks: tap to place (steps 0/1), drag to adjust (step 2)
  final Function(Position)? onCalibrationPlacePoint;
  final Function(Offset, double)? onCalibrationAdjustStart;
  final Function(Offset, double)? onCalibrationAdjustUpdate;
  final VoidCallback? onCalibrationAdjustEnd;

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
    required this.selectedWeapon,
    required this.onTapPosition,
    required this.onLongPressPosition,
    required this.onViewChanged,
    required this.calibrationOffsetX,
    required this.calibrationOffsetY,
    required this.calibrationScaleX,
    required this.calibrationScaleY,
    required this.calibrationMode,
    required this.isCalibrating,
    required this.calibrationStep,
    required this.calibPointA,
    required this.calibPointB,
    required this.isDraggingCalibration,
    required this.dragPosition,
    required this.onCalibrationDragStart,
    required this.onCalibrationDragUpdate,
    required this.onCalibrationDragEnd,
    this.onCalibrationPlacePoint,
    this.onCalibrationAdjustStart,
    this.onCalibrationAdjustUpdate,
    this.onCalibrationAdjustEnd,
  });

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  late final TransformationController _controller;
  final GlobalKey _gestureLayerKey = GlobalKey();
  bool _isUserInteracting = false;
  bool _isInitialized = false;
  Size _lastViewportSize = Size.zero;
  Size _lastSceneSize = Size.zero;
  Offset _lastBaseOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    debugPrint('Map screen init');
    _controller = TransformationController(Matrix4.identity());
    debugPrint('TransformationController initialized');
  }

  @override
  void didUpdateWidget(covariant _MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isUserInteracting) {
      return;
    }
    if (_lastViewportSize.width <= 0 ||
        _lastViewportSize.height <= 0 ||
        _lastSceneSize.width <= 0 ||
        _lastSceneSize.height <= 0) {
      return;
    }
    final desired = _stateToMatrix(
      baseOffset: _lastBaseOffset,
      zoom: widget.zoomLevel,
      panX: widget.panX,
      panY: widget.panY,
    );
    if (!_isMatrixClose(_controller.value, desired)) {
      _controller.value = desired;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Matrix4 _stateToMatrix({
    required Offset baseOffset,
    required double zoom,
    required double panX,
    required double panY,
  }) {
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, zoom);
    matrix.setEntry(1, 1, zoom);
    matrix.setEntry(2, 2, 1);
    matrix.setEntry(3, 3, 1);
    matrix.setTranslationRaw(baseOffset.dx + panX, baseOffset.dy + panY, 0);
    return matrix;
  }

  bool _isMatrixClose(Matrix4 a, Matrix4 b) {
    final sa = a.storage;
    final sb = b.storage;
    for (var i = 0; i < 16; i++) {
      if ((sa[i] - sb[i]).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Validate metadata
      if (widget.metadata.imageWidth <= 0 || widget.metadata.imageHeight <= 0) {
        return _buildErrorWidget('Invalid image dimensions');
      }

      // Validate image path
      if (widget.mapImagePath == null || widget.mapImagePath!.isEmpty) {
        return _buildErrorWidget('Image path is null');
      }
      
      final imagePath = widget.mapImagePath!;

      // Full layout with InteractiveViewer
      return LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          
          // Calculate map display size based on aspect ratio
          final imageWidth = widget.metadata.imageWidth.toDouble();
          final imageHeight = widget.metadata.imageHeight.toDouble();
          final imageAspect = imageWidth / imageHeight;

          var mapWidth = viewportWidth;
          var mapHeight = mapWidth / imageAspect;
          if (mapHeight > viewportHeight) {
            mapHeight = viewportHeight;
            mapWidth = mapHeight * imageAspect;
          }

          final baseOffset = Offset(
            (viewportWidth - mapWidth) / 2,
            (viewportHeight - mapHeight) / 2,
          );

          _lastViewportSize = Size(viewportWidth, viewportHeight);
          _lastSceneSize = Size(mapWidth, mapHeight);
          _lastBaseOffset = baseOffset;

          if (!_isUserInteracting) {
            final desired = _stateToMatrix(
              baseOffset: baseOffset,
              zoom: widget.zoomLevel,
              panX: widget.panX,
              panY: widget.panY,
            );
            if (!_isMatrixClose(_controller.value, desired)) {
              _controller.value = desired;
            }
          }

          // World coordinate conversion functions
          Position? sceneToWorld(Offset scenePoint) {
            final localX = scenePoint.dx;
            final localY = scenePoint.dy;
            if (localX < 0 || localY < 0 || localX > mapWidth || localY > mapHeight) {
              return null;
            }

            final normalizedX = localX / mapWidth;
            final normalizedY = localY / mapHeight;
            final correctedX = ((normalizedX - widget.calibrationOffsetX) / widget.calibrationScaleX).clamp(0.0, 1.0);
            final correctedY = ((normalizedY - widget.calibrationOffsetY) / widget.calibrationScaleY).clamp(0.0, 1.0);

            final worldX = correctedX * widget.metadata.worldSize;
            final worldY = (1 - correctedY) * widget.metadata.worldHeight;
            return Position(x: worldX, y: worldY);
          }

          Offset viewportToScene(Offset viewportPoint) {
            final inverted = Matrix4.copy(_controller.value);
            final determinant = inverted.invert();
            if (determinant == 0) return viewportPoint;
            return MatrixUtils.transformPoint(inverted, viewportPoint);
          }

          Offset sceneToViewport(Offset scenePoint) {
            return MatrixUtils.transformPoint(_controller.value, scenePoint);
          }

          Position? pointerToWorld(Offset globalPoint) {
            final context = _gestureLayerKey.currentContext;
            if (context == null) return null;
            final renderObject = context.findRenderObject();
            if (renderObject is! RenderBox) return null;

            final viewportPoint = renderObject.globalToLocal(globalPoint);
            final scenePoint = viewportToScene(viewportPoint);
            return sceneToWorld(scenePoint);
          }

          // Calibration points in scene coordinates (raw, without calibration during calibration mode)
          Offset? pointAOffset;
          Offset? pointBOffset;
          if (widget.calibPointA != null) {
            final normX = widget.calibPointA!.x / widget.metadata.worldSize;
            final normY = 1 - (widget.calibPointA!.y / widget.metadata.worldHeight);
            // During calibration, show raw positions; otherwise apply calibration
            final scaleX = widget.isCalibrating ? 1.0 : widget.calibrationScaleX;
            final scaleY = widget.isCalibrating ? 1.0 : widget.calibrationScaleY;
            final offsetX = widget.isCalibrating ? 0.0 : widget.calibrationOffsetX;
            final offsetY = widget.isCalibrating ? 0.0 : widget.calibrationOffsetY;
            pointAOffset = Offset(
              normX * mapWidth * scaleX + offsetX * mapWidth,
              normY * mapHeight * scaleY + offsetY * mapHeight,
            );
          }
          if (widget.calibPointB != null) {
            final normX = widget.calibPointB!.x / widget.metadata.worldSize;
            final normY = 1 - (widget.calibPointB!.y / widget.metadata.worldHeight);
            // During calibration, show raw positions; otherwise apply calibration
            final scaleX = widget.isCalibrating ? 1.0 : widget.calibrationScaleX;
            final scaleY = widget.isCalibrating ? 1.0 : widget.calibrationScaleY;
            final offsetX = widget.isCalibrating ? 0.0 : widget.calibrationOffsetX;
            final offsetY = widget.isCalibrating ? 0.0 : widget.calibrationOffsetY;
            pointBOffset = Offset(
              normX * mapWidth * scaleX + offsetX * mapWidth,
              normY * mapHeight * scaleY + offsetY * mapHeight,
            );
          }

          return Container(
            color: AppTheme.background,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _controller,
                    panEnabled: !widget.isCalibrating,
                    scaleEnabled: !widget.isCalibrating,
                    clipBehavior: Clip.hardEdge,
                    constrained: false,
                    minScale: 0.5,
                    maxScale: 8.0,
                    boundaryMargin: EdgeInsets.symmetric(
                      horizontal: viewportWidth,
                      vertical: viewportHeight,
                    ),
                    onInteractionStart: (_) {
                      _isUserInteracting = true;
                    },
                    onInteractionEnd: (_) {
                      _isUserInteracting = false;
                      final matrix = _controller.value.storage;
                      widget.onViewChanged(
                        _controller.value.getMaxScaleOnAxis(),
                        matrix[12] - baseOffset.dx,
                        matrix[13] - baseOffset.dy,
                      );
                    },
                    child: GestureDetector(
                      key: _gestureLayerKey,
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final world = sceneToWorld(details.localPosition);
                        if (world != null) {
                          if (widget.isCalibrating && widget.calibrationStep != null && widget.calibrationStep! < 2) {
                            widget.onCalibrationPlacePoint?.call(world);
                          } else {
                            widget.onTapPosition(world);
                          }
                        }
                      },
                      onLongPressStart: (details) {
                        debugPrint('LONG PRESS START: isCalibrating=${widget.isCalibrating}, step=${widget.calibrationStep}');
                        if (widget.isCalibrating && widget.calibrationStep == 2) {
                          debugPrint('LONG PRESS START: Calling calibrationAdjustStart at ${details.localPosition}');
                          widget.onCalibrationAdjustStart?.call(details.localPosition, widget.zoomLevel);
                        }
                      },
                      onLongPressMoveUpdate: (details) {
                        if (widget.isCalibrating && widget.calibrationStep == 2) {
                          widget.onCalibrationAdjustUpdate?.call(details.localPosition, widget.zoomLevel);
                        }
                      },
                      onLongPressEnd: (details) {
                        if (widget.isCalibrating && widget.calibrationStep == 2) {
                          widget.onCalibrationAdjustEnd?.call();
                        }
                      },
                      child: SizedBox(
                        width: mapWidth,
                        height: mapHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildMapImageOptimized(imagePath),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MapOverlayPainter(
                                  metadata: widget.metadata,
                                  markers: widget.markers,
                                  showGrid: widget.showGrid,
                                  showDistanceLine: widget.showDistanceLine,
                                  zoomLevel: widget.zoomLevel,
                                  selectedWeapon: widget.selectedWeapon,
                                  calibrationOffsetX: widget.calibrationOffsetX,
                                  calibrationOffsetY: widget.calibrationOffsetY,
                                  calibrationScaleX: widget.calibrationScaleX,
                                  calibrationScaleY: widget.calibrationScaleY,
                                  calibrationMode: widget.calibrationMode,
                                ),
                              ),
                            ),
                            if (pointAOffset != null && pointBOffset != null)
                              CustomPaint(
                                size: Size(mapWidth, mapHeight),
                                painter: _CalibrationLinePainter(
                                  pointA: pointAOffset,
                                  pointB: pointBOffset,
                                  zoomLevel: widget.zoomLevel,
                                ),
                              ),
                            if (pointAOffset != null)
                              Positioned(
                                left: pointAOffset.dx - 7 / widget.zoomLevel,
                                top: pointAOffset.dy - 7 / widget.zoomLevel,
                                child: CalibrationPointMarker(
                                  label: 'A',
                                  color: Colors.green,
                                  size: 14 / widget.zoomLevel,
                                ),
                              ),
                            if (pointBOffset != null)
                              Positioned(
                                left: pointBOffset.dx - 7 / widget.zoomLevel,
                                top: pointBOffset.dy - 7 / widget.zoomLevel,
                                child: CalibrationPointMarker(
                                  label: 'B',
                                  color: Colors.orange,
                                  size: 14 / widget.zoomLevel,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Magnifier glass in screen coordinates (outside InteractiveViewer)
                if (widget.isDraggingCalibration && widget.dragPosition != null) ...[
                  // Convert content coordinates to viewport coordinates for magnifier
                  Builder(builder: (context) {
                    final viewportPos = sceneToViewport(widget.dragPosition!);
                    return Stack(children: [
                      Positioned(
                        left: viewportPos.dx - 40,
                        top: viewportPos.dy - 100,
                        child: MagnifierGlass(
                          position: widget.dragPosition!,
                        ),
                      ),
                      Positioned(
                        left: viewportPos.dx - 20,
                        top: viewportPos.dy - 20,
                        child: Crosshair(),
                      ),
                    ]);
                  }),
                ],
                // Tap hint at top
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _TapHint(
                    hasMortar: widget.hasMortar,
                    hasTarget: widget.hasTarget,
                    isCalibrating: widget.calibrationMode,
                  ),
                ),
              ],
            ),
          );
        },
      );
      
    } catch (e, stackTrace) {
      debugPrint('=== MAP BUILD CRASH ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      return _buildErrorWidget('$e');
    }
  }

  Widget _buildMapImageOptimized(String imagePath) {
    // Use ResizeImage to limit memory usage
    final imageProvider = ResizeImage(
      AssetImage(imagePath),
      width: 1024,
      height: 1024,
      policy: ResizeImagePolicy.fit,
    );
    
    return Image(
      image: imageProvider,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('IMAGE ERROR: $error');
        return Container(
          color: Colors.red[900],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Image not found',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapImage() {
    debugPrint('_buildMapImage: mapImagePath = ${widget.mapImagePath}');
    if (widget.mapImagePath == null) {
      debugPrint('_buildMapImage: path is null, returning empty container');
      return Container(color: AppTheme.surfaceLight);
    }

    final path = widget.mapImagePath!;
    debugPrint('_buildMapImage: loading image from path: $path');
    if (path.startsWith('assets/')) {
      debugPrint('_buildMapImage: using Image.asset');
      return Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('_buildMapImage: Image.asset error: $error');
          return _mapUnavailable();
        },
      );
    }

    // On web, Image.file is not supported - use network or memory approach
    if (kIsWeb) {
      // For web, try to use the path as a network URL or show unavailable
      if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
        return Image.network(
          path,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, _, __) => _mapUnavailable(),
        );
      }
      // For local files on web, show unavailable message
      return Container(
        color: AppTheme.surfaceLight,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Local files not supported on web',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Use asset-based maps instead',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, __) => _mapUnavailable(),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: AppTheme.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 16),
          Text(
            'Map failed to load',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Using default scale',
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapUnavailable() {
    return Container(
      color: AppTheme.surfaceLight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Map image unavailable',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Path: ${widget.mapImagePath ?? 'null'}',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Painter for calibration line between points A and B
class _CalibrationLinePainter extends CustomPainter {
  final Offset pointA;
  final Offset pointB;
  final double zoomLevel;

  _CalibrationLinePainter({
    required this.pointA,
    required this.pointB,
    this.zoomLevel = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw dashed line between points
    final path = Path()
      ..moveTo(pointA.dx, pointA.dy)
      ..lineTo(pointB.dx, pointB.dy);

    final metric = path.computeMetrics().first;
    const dashLength = 10.0;
    const gapLength = 5.0;
    var distance = 0.0;

    while (distance < metric.length) {
      final next = math.min(distance + dashLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += dashLength + gapLength;
    }

    // Draw distance label at midpoint
    final mid = Offset((pointA.dx + pointB.dx) / 2, (pointA.dy + pointB.dy) / 2);
    final textSpan = TextSpan(
      text: '100m reference',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10 / zoomLevel,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MapOverlayPainter extends CustomPainter {
  final MapMetadata metadata;
  final List<MapMarker> markers;
  final bool showGrid;
  final bool showDistanceLine;
  final double zoomLevel;
  final String selectedWeapon;
  final double calibrationOffsetX;
  final double calibrationOffsetY;
  final double calibrationScaleX;
  final double calibrationScaleY;
  final bool calibrationMode;

  _MapOverlayPainter({
    required this.metadata,
    required this.markers,
    required this.showGrid,
    required this.showDistanceLine,
    required this.zoomLevel,
    required this.selectedWeapon,
    required this.calibrationOffsetX,
    required this.calibrationOffsetY,
    required this.calibrationScaleX,
    required this.calibrationScaleY,
    required this.calibrationMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Null safety checks - do not draw if metadata is missing or invalid
    if (size.width <= 0 || size.height <= 0) {
      debugPrint('GridPainter: Invalid size $size');
      return;
    }
    final metersPerPixel = metadata.worldSize / metadata.imageWidth;
    if (metersPerPixel <= 0 || metersPerPixel.isNaN || metersPerPixel.isInfinite) {
      debugPrint('GridPainter: Invalid metersPerPixel $metersPerPixel');
      return;
    }
    if (metadata.imageWidth <= 0 || metadata.imageHeight <= 0) {
      debugPrint('GridPainter: Invalid metadata image dimensions ${metadata.imageWidth} x ${metadata.imageHeight}');
      return;
    }
    if (metadata.worldSize <= 0 || metadata.worldHeight <= 0) {
      debugPrint('GridPainter: Invalid world size ${metadata.worldSize} x ${metadata.worldHeight}');
      return;
    }

    if (showGrid) {
      _drawGrid(canvas, size);
    }

    final mortar = _findMarker(MarkerType.mortar);
    if (mortar != null) {
      _drawMaxRangeRadius(canvas, size, mortar);
    }

    if (showDistanceLine) {
      final target = _findMarker(MarkerType.target);
      if (mortar != null && target != null) {
        _drawDistanceLine(canvas, size, mortar, target);
      }
    }

    for (final marker in markers) {
      _drawMarker(canvas, size, marker);
    }
  }

  void _drawMaxRangeRadius(Canvas canvas, Size size, MapMarker mortar) {
    final tables = BallisticTables.getTables(selectedWeapon);
    if (tables.isEmpty) {
      return;
    }
    final maxRange = tables.map((t) => t.maxRange).reduce(math.max);
    if (maxRange <= 0) {
      return;
    }

    // Calculate metersPerPixel (worldWidth / imageWidth)
    var metersPerPixel = metadata.worldSize / metadata.imageWidth;
    // Safety check: use default if calculation results in 0 or invalid
    if (metersPerPixel <= 0) {
      const defaultMetersPerPixel = 3.125; // 12800 / 4096
      metersPerPixel = defaultMetersPerPixel;
    }

    final center = _worldToPixel(mortar.position, size);
    final radiusPixels = maxRange / metersPerPixel;
    final displayScaleX = size.width / metadata.imageWidth;
    final displayScaleY = size.height / metadata.imageHeight;
    final radiusX = radiusPixels * displayScaleX * calibrationScaleX;
    final radiusY = radiusPixels * displayScaleY * calibrationScaleY;
    if (radiusX <= 1 || radiusY <= 1) {
      return;
    }

    final safeZoom = zoomLevel.clamp(0.25, 8.0);
    final paint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.45)
      ..strokeWidth = 1.2 / math.sqrt(safeZoom)
      ..style = PaintingStyle.stroke;

    final oval = Path()
      ..addOval(
        Rect.fromLTRB(
          center.dx - radiusX,
          center.dy - radiusY,
          center.dx + radiusX,
          center.dy + radiusY,
        ),
      );
    for (final metric in oval.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 9.0;
      const gapLength = 7.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    // Additional null safety checks
    if (metadata.worldSize <= 0 || metadata.worldHeight <= 0) {
      return;
    }
    if (metadata.gridSize <= 0) {
      return;
    }

    final safeZoom = zoomLevel.clamp(0.25, 8.0);
    final paint = Paint()
      ..color = AppTheme.gridLine.withValues(alpha: 0.35)
      ..strokeWidth = 0.6 / math.sqrt(safeZoom);

    // Calculate metersPerPixel for proper grid spacing
    var metersPerPixel = metadata.worldSize / metadata.imageWidth;
    // Safety check: use default if calculation results in 0 or invalid
    if (metersPerPixel <= 0) {
      const defaultMetersPerPixel = 3.125; // 12800 / 4096
      metersPerPixel = defaultMetersPerPixel;
    }

    for (double worldX = 0;
        worldX <= metadata.worldSize;
        worldX += metadata.gridSize) {
      final normalizedX = calibrationOffsetX +
          calibrationScaleX * (worldX / metadata.worldSize);
      final pixelX = normalizedX * size.width;
      canvas.drawLine(Offset(pixelX, 0), Offset(pixelX, size.height), paint);
    }
    for (double worldY = 0;
        worldY <= metadata.worldHeight;
        worldY += metadata.gridSize) {
      final normalizedY = calibrationOffsetY +
          calibrationScaleY * (1 - (worldY / metadata.worldHeight));
      final pixelY = normalizedY * size.height;
      canvas.drawLine(Offset(0, pixelY), Offset(size.width, pixelY), paint);
    }
  }

  void _drawDistanceLine(
      Canvas canvas, Size size, MapMarker mortar, MapMarker target) {
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
    textPainter.paint(
        canvas, Offset(mid.dx - textPainter.width / 2, mid.dy - 20));
  }

  void _drawMarker(Canvas canvas, Size size, MapMarker marker) {
    final position = _worldToPixel(marker.position, size);
    final safeZoom = zoomLevel.clamp(0.25, 5.0);
    final baseRadius =
        marker.type == MarkerType.mortar || marker.type == MarkerType.target
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
    final normalizedX = calibrationOffsetX +
        calibrationScaleX * (position.x / metadata.worldSize);
    final normalizedY = calibrationOffsetY +
        calibrationScaleY * (1 - (position.y / metadata.worldHeight));

    final x = normalizedX * size.width;
    final y = normalizedY * size.height;
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
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.selectedWeapon != selectedWeapon ||
        oldDelegate.calibrationOffsetX != calibrationOffsetX ||
        oldDelegate.calibrationOffsetY != calibrationOffsetY ||
        oldDelegate.calibrationScaleX != calibrationScaleX ||
        oldDelegate.calibrationScaleY != calibrationScaleY ||
        oldDelegate.calibrationMode != calibrationMode;
  }
}

class _TapHint extends StatelessWidget {
  final bool hasMortar;
  final bool hasTarget;
  final bool isCalibrating;

  const _TapHint({
    required this.hasMortar,
    required this.hasTarget,
    this.isCalibrating = false,
  });

  @override
  Widget build(BuildContext context) {
    final message = isCalibrating
        ? 'Calibration mode - Tap map to set reference points'
        : !hasMortar
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
            Icon(
              isCalibrating ? Icons.straighten : Icons.touch_app,
              size: 18,
              color: isCalibrating ? AppTheme.accent : AppTheme.accent,
            ),
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
  final String selectedWeapon;
  final List<String> availableWeapons;
  final ValueChanged<String?> onWeaponSelected;
  final VoidCallback onClear;

  const _BottomPanel({
    required this.hasMortar,
    required this.hasTarget,
    this.error,
    this.solution,
    required this.selectedWeapon,
    required this.availableWeapons,
    required this.onWeaponSelected,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedWeapon.isEmpty ? null : selectedWeapon,
                        dropdownColor: AppTheme.surfaceLight,
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        icon:
                            Icon(Icons.arrow_drop_down, color: AppTheme.accent),
                        items: availableWeapons.map((weapon) {
                          return DropdownMenuItem<String>(
                            value: weapon,
                            child: Text(weapon),
                          );
                        }).toList(),
                        onChanged: (value) {
                          onWeaponSelected(value);
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
                      Icon(Icons.error_outline,
                          color: AppTheme.danger, size: 20),
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
                      Icon(Icons.info_outline,
                          color: AppTheme.textMuted, size: 20),
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
