import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:provider/provider.dart';

import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';

import 'package:cognifind/indoor_engine/utils/indoor_route_progress.dart';

import 'package:cognifind/indoor_engine/widgets/painters/indoor_route_painter.dart';

import 'package:cognifind/indoor_engine/widgets/overlays/indoor_blue_dot.dart';

import 'package:cognifind/indoor_engine/widgets/overlays/indoor_destination_marker.dart';

class IndoorMapCanvas extends StatelessWidget {

  final String svgPath;

  final Size viewBoxSize;

  final int floor;

  const IndoorMapCanvas({
    super.key,
    required this.svgPath,
    required this.viewBoxSize,
    required this.floor,
  });

  @override
  Widget build(BuildContext context) {

    final provider =
    context.watch<
        IndoorNavigationProvider>();

    /// =====================================
    /// NODES FOR CURRENT FLOOR
    /// =====================================

    final nodesOnFloor =
    provider.indoorPathForFloor(
      floor,
    );

    /// Render-space diagnostic: canvas size (== SVG viewBox) and raw nodes.
    assert(() {
      debugPrint(
        '[INDOOR RENDER] floor=$floor svg=$svgPath '
        'canvas=${viewBoxSize.width}x${viewBoxSize.height} '
        'nodes=${nodesOnFloor.map((n) => "${n.id}(${n.x.toStringAsFixed(1)},${n.y.toStringAsFixed(1)})").join(" ")}',
      );
      return true;
    }());

    /// =====================================
    /// PROGRESS ON THIS FLOOR
    /// =====================================
    ///
    /// Map the app-wide progress index (currentIndoorIndex — the same
    /// position-driven "nearest route node" that drives the instruction card)
    /// to a LOCAL index within this floor's contiguous node slice. < 0 means
    /// the user hasn't reached this floor yet (whole route remaining); beyond
    /// the last node means the floor is already passed (whole route traversed).

    final currentLocalIndex = indoorCurrentLocalIndex(
      provider.indoorPath,
      provider.currentIndoorIndex,
      floor,
    );

    /// =====================================
    /// LIVE POSITION
    /// =====================================

    final currentPosition =
        provider.position;

    /// =====================================
    /// DESTINATION NODE (final route node)
    /// =====================================

    final destination = provider.destinationNode;

    return Align(

      alignment: Alignment.center,

      child: FittedBox(

        fit: BoxFit.contain,

        child: SizedBox(

          width: viewBoxSize.width,

          height: viewBoxSize.height,

          child: Stack(

            children: [

              /// =====================================
              /// SVG FLOOR
              /// =====================================

              Positioned.fill(

                child: SvgPicture.asset(

                  svgPath,

                  key: ValueKey(svgPath),

                  fit: BoxFit.fill,
                ),
              ),

              /// =====================================
              /// ROUTE LAYER
              /// =====================================

              Positioned.fill(

                child: CustomPaint(

                  painter: IndoorRoutePainter(

                    nodes: nodesOnFloor,

                    currentLocalIndex:
                    currentLocalIndex,
                  ),
                ),
              ),

              /// =====================================
              /// DESTINATION MARKER (final node, this floor)
              /// =====================================

              if (destination != null &&
                  destination.floor == floor)

                IndoorDestinationMarker(
                  position: Offset(
                    destination.x,
                    destination.y,
                  ),
                ),

              /// =====================================
              /// LIVE BLUE DOT
              /// =====================================

              if (currentPosition.floor == floor)

                IndoorBlueDot(

                  position: Offset(
                    currentPosition.x,
                    currentPosition.y,
                  ),

                  heading: currentPosition.heading,
                ),
            ],
          ),
        ),
      ),
    );
  }
}