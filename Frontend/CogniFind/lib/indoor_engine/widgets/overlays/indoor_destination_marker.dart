import 'package:flutter/material.dart';

/// Pulsing destination pin for the indoor route's final node (the target room).
///
/// A direct child of the indoor canvas [Stack] — it self-positions via
/// [Positioned] in SVG/viewBox coordinates (same convention as IndoorBlueDot),
/// so it scales with the map. The pin's tip sits exactly on the node point; a
/// soft halo pings outward from that point so the destination reads instantly
/// as "this is your room".
class IndoorDestinationMarker extends StatefulWidget {
  /// Destination node position in viewBox coordinates.
  final Offset position;

  const IndoorDestinationMarker({
    super.key,
    required this.position,
  });

  @override
  State<IndoorDestinationMarker> createState() =>
      _IndoorDestinationMarkerState();
}

class _IndoorDestinationMarkerState extends State<IndoorDestinationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// Bounding box for the pin + halo. The pin tip is the bottom-center.
  static const double _box = 64;

  static const Color _accent = Color(0xFFE53935); // destination red

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      /// Pin tip (bottom-center of the box) lands on the node point.
      left: widget.position.dx - _box / 2,
      top: widget.position.dy - _box,
      child: IgnorePointer(
        child: SizedBox(
          width: _box,
          height: _box,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              /// Ground halo pinging outward from the pin tip.
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final t = _pulse.value; // 0 → 1
                  final size = 22 + t * 30; // expands 22 → 52
                  final opacity = (1 - t) * 0.35;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),

              /// Pin body.
              const Icon(
                Icons.place,
                color: _accent,
                size: 46,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 4),
                ],
              ),

              /// White eye on the pin head.
              const Positioned(
                top: 9,
                child: Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
