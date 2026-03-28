import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../ballistics/ballistics.dart';
import '../../maps/cubit/map_cubit.dart';
import '../../maps/maps.dart';
import '../../models/models.dart';
import '../widgets/firing_solution_card.dart';

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
    await _showCalibrationDialog(context, state);
    if (mounted) {
      setState(() => _calibrationMode = false);
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
                _openCalibrationDialog(context, context.read<MapCubit>().state);
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
                selectedMortar: state.selectedMortar,
                onTapPosition: (position) =>
                    _handleTap(context, state, position),
                onLongPressPosition: (position) {
                  context.read<MapCubit>().addMortar(position);
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
                  onMortarSelected: (type) =>
                      context.read<MapCubit>().setMortarType(type),
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

  Future<void> _showCalibrationDialog(
      BuildContext context, MapState state) async {
    final cubit = context.read<MapCubit>();
    final initialOffsetX = state.calibrationOffsetX;
    final initialOffsetY = state.calibrationOffsetY;
    final initialScaleX = state.calibrationScaleX;
    final initialScaleY = state.calibrationScaleY;
    var didSave = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        double offsetX = initialOffsetX;
        double offsetY = initialOffsetY;
        double scaleX = initialScaleX;
        double scaleY = initialScaleY;
        double stepPercent = 0.10;
        const pivotX = 0.5;
        const pivotY = 0.5;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            void previewCurrent() {
              cubit.setCalibration(
                offsetX: offsetX,
                offsetY: offsetY,
                scaleX: scaleX,
                scaleY: scaleY,
                persist: false,
              );
            }

            void nudge({
              double dx = 0,
              double dy = 0,
              double dsx = 0,
              double dsy = 0,
            }) {
              final step = stepPercent / 100.0;
              setLocalState(() {
                offsetX += dx * step;
                offsetY += dy * step;
                if (dsx != 0) {
                  final nextScaleX =
                      (scaleX + dsx * step).clamp(0.5, 1.5).toDouble();
                  offsetX += (scaleX - nextScaleX) * pivotX;
                  scaleX = nextScaleX;
                }
                if (dsy != 0) {
                  final nextScaleY =
                      (scaleY + dsy * step).clamp(0.5, 1.5).toDouble();
                  offsetY += (scaleY - nextScaleY) * pivotY;
                  scaleY = nextScaleY;
                }
                offsetX = offsetX.clamp(-0.5, 0.5).toDouble();
                offsetY = offsetY.clamp(-0.5, 0.5).toDouble();
              });
              previewCurrent();
            }

            Widget nudgeButton({
              required String label,
              required VoidCallback onPressed,
            }) {
              return Expanded(
                child: OutlinedButton(
                  onPressed: onPressed,
                  child: Text(label),
                ),
              );
            }

            final maxHeight = MediaQuery.of(sheetContext).size.height * 0.60;

            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: 760, maxHeight: maxHeight),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.gridLine),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'GRID CALIBRATION',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Map stays visible while adjusting. Changes apply instantly.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Step',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      [0.05, 0.10, 0.25, 0.50].map((step) {
                                    return ChoiceChip(
                                      label:
                                          Text('${step.toStringAsFixed(2)}%'),
                                      selected: stepPercent == step,
                                      onSelected: (_) => setLocalState(
                                        () => stepPercent = step,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: AppTheme.gridLine),
                                  ),
                                  child: Text(
                                    'OffsetX: ${(offsetX * 100).toStringAsFixed(2)}%  '
                                    'OffsetY: ${(offsetY * 100).toStringAsFixed(2)}%\n'
                                    'ScaleX: x${scaleX.toStringAsFixed(4)}  '
                                    'ScaleY: x${scaleY.toStringAsFixed(4)}\n'
                                    'Grid size: ${state.currentMetadata?.gridSize.toStringAsFixed(0) ?? '-'}m',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    nudgeButton(
                                      label: 'Left',
                                      onPressed: () => nudge(dx: -1),
                                    ),
                                    const SizedBox(width: 8),
                                    nudgeButton(
                                      label: 'Right',
                                      onPressed: () => nudge(dx: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    nudgeButton(
                                      label: 'Up',
                                      onPressed: () => nudge(dy: -1),
                                    ),
                                    const SizedBox(width: 8),
                                    nudgeButton(
                                      label: 'Down',
                                      onPressed: () => nudge(dy: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    nudgeButton(
                                      label: 'Less',
                                      onPressed: () => nudge(dsx: -1, dsy: -1),
                                    ),
                                    const SizedBox(width: 8),
                                    nudgeButton(
                                      label: 'More',
                                      onPressed: () => nudge(dsx: 1, dsy: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    nudgeButton(
                                      label: 'Width -',
                                      onPressed: () => nudge(dsx: -1),
                                    ),
                                    const SizedBox(width: 8),
                                    nudgeButton(
                                      label: 'Width +',
                                      onPressed: () => nudge(dsx: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    nudgeButton(
                                      label: 'Height -',
                                      onPressed: () => nudge(dsy: -1),
                                    ),
                                    const SizedBox(width: 8),
                                    nudgeButton(
                                      label: 'Height +',
                                      onPressed: () => nudge(dsy: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setLocalState(() {
                                          offsetX = 0;
                                          offsetY = 0;
                                          scaleX = 1;
                                          scaleY = 1;
                                        });
                                        previewCurrent();
                                      },
                                      child: const Text('RESET'),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () {
                                        didSave = true;
                                        cubit.setCalibration(
                                          offsetX: offsetX,
                                          offsetY: offsetY,
                                          scaleX: scaleX,
                                          scaleY: scaleY,
                                          persist: true,
                                        );
                                        Navigator.pop(sheetContext);
                                      },
                                      child: const Text('SAVE'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!didSave) {
      cubit.setCalibration(
        offsetX: initialOffsetX,
        offsetY: initialOffsetY,
        scaleX: initialScaleX,
        scaleY: initialScaleY,
        persist: false,
      );
    }
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
  final String selectedMortar;
  final ValueChanged<Position> onTapPosition;
  final ValueChanged<Position> onLongPressPosition;
  final void Function(double zoom, double panX, double panY) onViewChanged;
  final double calibrationOffsetX;
  final double calibrationOffsetY;
  final double calibrationScaleX;
  final double calibrationScaleY;
  final bool calibrationMode;

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
    required this.selectedMortar,
    required this.onTapPosition,
    required this.onLongPressPosition,
    required this.onViewChanged,
    required this.calibrationOffsetX,
    required this.calibrationOffsetY,
    required this.calibrationScaleX,
    required this.calibrationScaleY,
    required this.calibrationMode,
  });

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  late final TransformationController _controller;
  final GlobalKey _gestureLayerKey = GlobalKey();
  bool _isUserInteracting = false;
  Size _lastViewportSize = Size.zero;
  Size _lastSceneSize = Size.zero;
  Offset _lastBaseOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController(Matrix4.identity());
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;
        final imageAspect = widget.metadata.imageWidth / widget.metadata.imageHeight;

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

        Position? sceneToWorld(Offset scenePoint) {
          final localX = scenePoint.dx;
          final localY = scenePoint.dy;
          if (localX < 0 ||
              localY < 0 ||
              localX > mapWidth ||
              localY > mapHeight) {
            return null;
          }

          final normalizedX = localX / mapWidth;
          final normalizedY = localY / mapHeight;
          final correctedX = ((normalizedX - widget.calibrationOffsetX) /
                  widget.calibrationScaleX)
              .clamp(0.0, 1.0);
          final correctedY = ((normalizedY - widget.calibrationOffsetY) /
                  widget.calibrationScaleY)
              .clamp(0.0, 1.0);

          final worldX = correctedX * widget.metadata.worldSize;
          final worldY = (1 - correctedY) * widget.metadata.worldHeight;
          return Position(x: worldX, y: worldY);
        }

        Offset viewportToScene(Offset viewportPoint) {
          final inverted = Matrix4.copy(_controller.value);
          final determinant = inverted.invert();
          if (determinant == 0) {
            return viewportPoint;
          }
          return MatrixUtils.transformPoint(inverted, viewportPoint);
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

        return Container(
          color: AppTheme.background,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: _gestureLayerKey,
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final world = pointerToWorld(details.globalPosition);
                    if (world != null) {
                      widget.onTapPosition(world);
                    }
                  },
                  onLongPressStart: (details) {
                    final world = pointerToWorld(details.globalPosition);
                    if (world != null) {
                      widget.onLongPressPosition(world);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _controller,
                    panEnabled: true,
                    scaleEnabled: true,
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
                    child: SizedBox(
                      width: mapWidth,
                      height: mapHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildMapImage()),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MapOverlayPainter(
                                metadata: widget.metadata,
                                markers: widget.markers,
                                showGrid: widget.showGrid,
                                showDistanceLine: widget.showDistanceLine,
                                zoomLevel: widget.zoomLevel,
                                selectedMortar: widget.selectedMortar,
                                calibrationOffsetX: widget.calibrationOffsetX,
                                calibrationOffsetY: widget.calibrationOffsetY,
                                calibrationScaleX: widget.calibrationScaleX,
                                calibrationScaleY: widget.calibrationScaleY,
                                calibrationMode: widget.calibrationMode,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _TapHint(
                    hasMortar: widget.hasMortar, hasTarget: widget.hasTarget),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapImage() {
    if (widget.mapImagePath == null) {
      return Container(color: AppTheme.surfaceLight);
    }

    final path = widget.mapImagePath!;
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, _, __) => _mapUnavailable(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, __) => _mapUnavailable(),
    );
  }

  Widget _mapUnavailable() {
    return Container(
      color: AppTheme.surfaceLight,
      alignment: Alignment.center,
      child: Text(
        'Map image unavailable',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _MapOverlayPainter extends CustomPainter {
  final MapMetadata metadata;
  final List<MapMarker> markers;
  final bool showGrid;
  final bool showDistanceLine;
  final double zoomLevel;
  final String selectedMortar;
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
    required this.selectedMortar,
    required this.calibrationOffsetX,
    required this.calibrationOffsetY,
    required this.calibrationScaleX,
    required this.calibrationScaleY,
    required this.calibrationMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
    final tables = BallisticTables.getTables(selectedMortar);
    if (tables.isEmpty) {
      return;
    }
    final maxRange = tables.map((t) => t.maxRange).reduce(math.max);
    if (maxRange <= 0) {
      return;
    }

    final center = _worldToPixel(mortar.position, size);
    final radiusImagePixels = maxRange / metadata.metersPerPixel;
    final displayScaleX = size.width / metadata.imageWidth;
    final displayScaleY = size.height / metadata.imageHeight;
    final radiusX = radiusImagePixels * displayScaleX * calibrationScaleX;
    final radiusY = radiusImagePixels * displayScaleY * calibrationScaleY;
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
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
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
    final safeZoom = zoomLevel.clamp(0.25, 8.0);
    final gridColor = calibrationMode
        ? const Color(0xFF3BFF5B)
        : AppTheme.gridLine.withValues(alpha: 0.35);
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = (calibrationMode ? 1.6 : 0.6) / math.sqrt(safeZoom);

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
        oldDelegate.selectedMortar != selectedMortar ||
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMortar,
                        dropdownColor: AppTheme.surfaceLight,
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        icon:
                            Icon(Icons.arrow_drop_down, color: AppTheme.accent),
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
