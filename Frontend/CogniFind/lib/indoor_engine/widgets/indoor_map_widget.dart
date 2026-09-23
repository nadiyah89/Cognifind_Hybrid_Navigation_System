import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cognifind/widgets/navigation/map_controls_widget.dart';
import 'package:provider/provider.dart';
import 'package:cognifind/indoor_engine/widgets/indoor_map_canvas.dart';
import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';
import 'package:cognifind/core/config/indoor_building_config.dart';
import 'package:cognifind/core/config/demo_config.dart';
import 'package:cognifind/providers/navigation_provider.dart';
/// IndoorMapWidget
///
/// Fullscreen indoor map per building + floor.
class IndoorMapWidget extends StatefulWidget {
  final String? buildingId;
  final int floor;

  const IndoorMapWidget({
    super.key,
    required this.buildingId,
    required this.floor,
  });

  @override
  State<IndoorMapWidget> createState() => _IndoorMapWidgetState();
}

class _IndoorMapWidgetState extends State<IndoorMapWidget> {
  final TransformationController _controller = TransformationController();
  bool _initialized = false;

  /// Last indoor position the viewport was centred on, so unrelated rebuilds
  /// don't re-issue the same transform.
  Offset? _lastFollowedPosition;

  /// Per-floor rendering config (SVG asset + viewBox) for the given building +
  /// floor, sourced from the central [indoorBuildingConfigs] registry. Null
  /// when the building has no indoor map yet or the floor doesn't exist.
  IndoorFloorConfig? _floorConfig(String? buildingId, int floor) {
    return indoorBuildingConfigFor(buildingId)?.floor(floor);
  }

  // ---------- ZOOM CONTROLS ----------

  void _zoomIn() {
    _applyIncrementalZoom(1.2);
  }

  void _zoomOut() {
    _applyIncrementalZoom(1 / 1.2);
  }

  void _resetView() {
    _applyCenteredZoom(2.7);
  }

  /// Small per-floor vertical pan to improve framing.
  ///
  /// This pans the *entire* canvas (image + overlays) so alignment is preserved.
  double _initialPanY(double viewportHeight, double scale) {
    // Per-floor framing nudge from the central config (e.g. AB-IV floor 1
    // renders a bit low and is lifted slightly). Independent of scale.
    final factor =
        _floorConfig(widget.buildingId, widget.floor)?.initialPanFactor ?? 0;
    if (factor == 0) return 0;
    return (viewportHeight * factor) / scale;
  }

  @override
  void initState() {
    super.initState();

    // Start slightly zoomed-in and centered when opening an indoor map.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized) {
        _applyCenteredZoom(2.7);
        _initialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant IndoorMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.floor != widget.floor ||
        oldWidget.buildingId != widget.buildingId) {
      _resetView();
    }
  }
  /// Converts a point in SVG user space (the coordinate system the backend's
  /// route nodes and the blue dot live in) to a point in this widget's own
  /// coordinates.
  ///
  /// The two are NOT the same. [IndoorMapCanvas] hands the InteractiveViewer a
  /// child that fills the viewport, inside which a `FittedBox(BoxFit.contain)`
  /// shrinks the floor plan's viewBox to fit and centres it — so a node at
  /// SVG (680, 840) is nowhere near widget (680, 840). Centring the viewport on
  /// the raw SVG coordinate translated the whole canvas clean off-screen, which
  /// is why the indoor map went blank.
  Offset _svgToLocal(Offset svgPoint, Size viewport, Size viewBox) {
    final fit = math.min(
      viewport.width / viewBox.width,
      viewport.height / viewBox.height,
    );

    return Offset(
      (viewport.width - viewBox.width * fit) / 2 + svgPoint.dx * fit,
      (viewport.height - viewBox.height * fit) / 2 + svgPoint.dy * fit,
    );
  }

  /// Centres the viewport on [svgPoint], keeping the current zoom.
  void _centerOnSvgPoint(Offset svgPoint) {
    final viewBox = _floorConfig(widget.buildingId, widget.floor)?.viewBox;
    if (viewBox == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewport = renderBox.size;
    final local = _svgToLocal(svgPoint, viewport, viewBox);
    final scale = _controller.value.getMaxScaleOnAxis();

    _controller.value = Matrix4.identity()
      ..translate(viewport.width / 2, viewport.height / 2)
      ..scale(scale)
      ..translate(-local.dx, -local.dy);
  }

  /// Keeps the walking user centred on the floor plan while a route is being
  /// followed, at whatever zoom the user has chosen.
  ///
  /// Only while navigating, and only until the user pans or zooms away —
  /// [IndoorNavigationProvider.autoFollow] is the same opt-out the floor
  /// selector already uses, and the Locate Me control re-engages it. The
  /// transform is set directly rather than animated because the position
  /// arrives as a continuous stream; each frame's step is small, so setting it
  /// per frame IS the smooth motion.
  void _followUser(IndoorNavigationProvider provider) {
    if (!provider.autoFollow) return;

    final position = provider.position;
    if (position.floor != widget.floor) return;

    final target = Offset(position.x, position.y);
    if (target == _lastFollowedPosition) return;
    _lastFollowedPosition = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnSvgPoint(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final floorConfig = _floorConfig(widget.buildingId, widget.floor);
    final svgPath = floorConfig?.svgAsset;
    final viewBoxSize = floorConfig?.viewBox;

    /// Camera follow is demo-only for now: in production the indoor position
    /// arrives as sparse BLE fixes, which would jerk the viewport rather than
    /// glide it. The condition is a compile-time constant, so this and the
    /// watch below vanish entirely when demo mode is off.
    if (kDemoNavigationMode) {
      final indoorProvider = context.watch<IndoorNavigationProvider>();
      if (context.watch<NavigationProvider>().isNavigating) {
        _followUser(indoorProvider);
      }
    }

    if (svgPath == null || viewBoxSize == null) {
      // No indoor map for this building yet.
      return Stack(
        children: [
          const Center(
            child: Text(
              'Indoor map for this building is coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Still show zoom/reset controls to keep layout consistent.
          Positioned(
            right: 12,
            bottom: 120,
            child: MapControlsWidget(
              onMyLocation: () => _locateMe(context.read<IndoorNavigationProvider>()),
              onCenter: _resetView,
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        /// FULLSCREEN INDOOR MAP
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _controller,
            
            minScale: 1,
            maxScale: 5,
            boundaryMargin: const EdgeInsets.all(200),
            child: IndoorMapCanvas(
              svgPath: svgPath,
              viewBoxSize: viewBoxSize,
              floor: widget.floor,
            ),
          ),
        ),

        /// FLOOR LABEL
        Positioned(
          top: 12,
          left: 16,
          child: Chip(
            label: Text(
              floorConfig?.label ??
                  (widget.floor == 0
                      ? 'Ground Floor'
                      : 'Floor ${widget.floor}'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        /// RIGHT SIDEBAR CONTROLS (SAME AS OUTDOOR)
        Positioned(
          right: 12,
          bottom: 120,
          child: MapControlsWidget(
            onMyLocation: () =>
                _locateMe(context.read<IndoorNavigationProvider>()),
            onCenter: _resetView,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
          ),
        ),
      ],
    );
  }

  /// Applies a zoom centered on the widget's viewport so that
  /// the floor plan stays mostly within the visible area.
  void _applyCenteredZoom(double scale) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final panY = _initialPanY(size.height, scale);
    final matrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2 + panY)
      ..scale(scale)
      ..translate(-size.width / 2, -size.height / 2);

    setState(() {
      _controller.value = matrix;
    });
  }

  /// Re-engages auto-follow mode and centers the viewport on the user's current indoor position.
  void _locateMe(IndoorNavigationProvider provider) {
    provider.enableAutoFollow();

    final position = provider.position;
    setState(() {
      _centerOnSvgPoint(Offset(position.x, position.y));
    });
  }

  /// Applies an incremental zoom around the current center,
  /// clamped between the InteractiveViewer's min/max scale.
  void _applyIncrementalZoom(double factor) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Current scale from the transformation matrix.
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(1.0, 5.0);

    // If clamped value didn't change, no need to update.
    if ((newScale - currentScale).abs() < 0.01) return;

    final size = renderBox.size;
    final scaleFactor = newScale / currentScale;

    final matrix = _controller.value.clone()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scaleFactor)
      ..translate(-size.width / 2, -size.height / 2);

    setState(() {
      _controller.value = matrix;
    });
  }
}
