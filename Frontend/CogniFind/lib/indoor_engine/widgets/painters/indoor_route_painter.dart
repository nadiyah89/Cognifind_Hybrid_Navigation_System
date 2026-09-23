import 'package:flutter/material.dart';
import 'package:cognifind/models/navigation/indoor_node.dart';

/// Render-space debug toggle. When true, overlays the canvas frame + raw node
/// coordinates so route/SVG alignment can be re-verified visually (used to
/// confirm the floor-1 viewBox = canvas = 1554.0925×1100 fix). Off in normal
/// builds; flip to true to diagnose coordinate-space issues.
const bool kIndoorRenderDebug = false;

class IndoorRoutePainter extends CustomPainter {
  final List<IndoorNode> nodes;

  /// Local index (within [nodes]) of the current route node on this floor,
  /// derived from the app-wide position-driven progress index (the SAME index
  /// that drives the instruction card). < 0 → the user hasn't reached this
  /// floor yet (whole route remaining); >= nodes.length → the floor is already
  /// passed (whole route traversed). This is the single "current progress"
  /// definition — the route split below never invents a second one.
  final int currentLocalIndex;

  IndoorRoutePainter({
    required this.nodes,
    required this.currentLocalIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (kIndoorRenderDebug) {
      _paintDebug(canvas, size);
    }

    if (nodes.length < 2) return;

    /// Split the polyline at the current node, mirroring the outdoor
    /// traversed/remaining split: nodes[0..current] are consumed (dimmed) and
    /// nodes[current..end] remain highlighted. The two strokes overlap by one
    /// node so they meet with no gap. Clamps make the out-of-range cases fall
    /// out naturally — all-remaining before the floor, all-traversed after it.
    final split = currentLocalIndex.clamp(0, nodes.length);
    final traversed =
        nodes.sublist(0, (currentLocalIndex + 1).clamp(0, nodes.length));
    final remaining = nodes.sublist(split);

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withOpacity(0.15);

    final traversedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.indigo.withOpacity(0.22);

    final remainingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.indigo.withOpacity(0.85);

    /// Shadow under the whole route, then dim traversed + bright remaining.
    canvas.drawPath(_polyline(nodes), shadowPaint);
    if (traversed.length >= 2) {
      canvas.drawPath(_polyline(traversed), traversedPaint);
    }
    if (remaining.length >= 2) {
      canvas.drawPath(_polyline(remaining), remainingPaint);
    }

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isCurrent = i == currentLocalIndex;
      final isTraversed = i < currentLocalIndex;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isCurrent
            ? Colors.orange
            : (isTraversed
                ? Colors.white.withOpacity(0.5)
                : Colors.white);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 4 : 3
        ..color = isCurrent
            ? Colors.deepOrange
            : (isTraversed
                ? Colors.indigo.withOpacity(0.3)
                : Colors.indigo);

      final radius = isCurrent ? 10.0 : (isTraversed ? 6.0 : 7.0);

      canvas.drawCircle(
        Offset(node.x, node.y),
        radius,
        fillPaint,
      );

      canvas.drawCircle(
        Offset(node.x, node.y),
        radius,
        strokePaint,
      );
    }
  }

  /// Builds a stroke path through [pts] in order.
  Path _polyline(List<IndoorNode> pts) {
    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (final n in pts.skip(1)) {
      path.lineTo(n.x, n.y);
    }
    return path;
  }

  /// Render-space diagnostic overlay. Draws the CustomPaint frame (which equals
  /// the canvas Size, which must equal the SVG viewBox) and each node at its
  /// RAW backend coordinate with no transform. If the frame traces the SVG's
  /// outer wall and nodes land on stairwells/corridors, the coordinate spaces
  /// are synchronized.
  void _paintDebug(Canvas canvas, Size size) {
    /// Canvas frame + corner ticks.
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.pink;
    canvas.drawRect(Offset.zero & size, framePaint);

    final cornerPaint = Paint()..color = Colors.pink;
    for (final c in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      canvas.drawCircle(c, 14, cornerPaint);
    }

    /// Raw nodes (no transform) with index + coordinate labels.
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final p = Offset(n.x, n.y);

      canvas.drawCircle(
        p,
        12,
        Paint()..color = Colors.green.withOpacity(0.9),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '$i:${n.id}\n(${n.x.toStringAsFixed(0)},${n.y.toStringAsFixed(0)})',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            backgroundColor: Color(0xAAFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p + const Offset(10, -8));
    }
  }

  @override
  bool shouldRepaint(
      covariant IndoorRoutePainter oldDelegate) {
    if (oldDelegate.currentLocalIndex != currentLocalIndex) {
      return true;
    }

    if (oldDelegate.nodes.length != nodes.length) {
      return true;
    }

    for (var i = 0; i < nodes.length; i++) {
      final a = nodes[i];
      final b = oldDelegate.nodes[i];

      if (a.id != b.id ||
          a.floor != b.floor ||
          a.x != b.x ||
          a.y != b.y ||
          a.type != b.type) {
        return true;
      }
    }

    return false;
  }
}