/// ======================================================
/// AUTOMATIC OUTDOOR -> INDOOR TRANSITION EVALUATOR
/// ======================================================
///
/// Pure, deterministic, side-effect-free decision logic for the automatic
/// indoor-transition trigger. Given a snapshot of the current situation, it
/// answers a single question: "is the user eligible to auto-enter the
/// building *right now*?".
///
/// It deliberately does NOT own any of the following (which live in
/// NavigationProvider):
/// - debounce / consecutive-hit counting across ticks
/// - single-fire lifecycle state
/// - the actual transition (enterIndoorTransition)
///
/// And it does NOT read live providers, GPS, or BLE directly — the driver
/// (RealtimePositionProvider) computes the raw inputs and passes an immutable
/// snapshot in. This keeps the trigger logic fully unit-testable.
library;

/// Tunable thresholds for the automatic transition trigger. Conservative
/// defaults; tuned later with real-world telemetry before auto-fire is
/// enabled.
class AutoTransitionConfig {
  const AutoTransitionConfig({
    this.entranceRadiusMeters = 15,
    this.minBeaconRssi = -70,
    this.requiredConsecutiveHits = 3,
  });

  /// Max GPS distance (meters) from the building entrance to be "at" it.
  final double entranceRadiusMeters;

  /// Minimum strongest-beacon RSSI (dBm) for beacon confidence.
  final int minBeaconRssi;

  /// How many consecutive eligible evaluations are required before firing
  /// (debounce — kills single-sample false positives and oscillation).
  /// Enforced by NavigationProvider, not the evaluator.
  final int requiredConsecutiveHits;
}

/// Immutable snapshot of everything the evaluator needs for one decision.
class AutoTransitionInputs {
  const AutoTransitionInputs({
    required this.isOutdoor,
    required this.transitionIdle,
    required this.alreadyFired,
    required this.hasIndoorDestination,
    required this.indoorPathReady,
    required this.distanceToEntranceMeters,
    required this.strongestRssi,
  });

  /// navigationMode == outdoor
  final bool isOutdoor;

  /// transitionPhase == none (not already transitioning)
  final bool transitionIdle;

  /// This route already auto-fired once (single-fire protection).
  final bool alreadyFired;

  /// transitionIndoorNode != null (a hybrid route with an indoor destination).
  final bool hasIndoorDestination;

  /// hybridIndoorPath is non-empty (indoor route preloaded and ready).
  final bool indoorPathReady;

  /// GPS distance to the building entrance, or null if unknown.
  final double? distanceToEntranceMeters;

  /// Strongest nearby beacon RSSI (dBm), or null if no beacon.
  final int? strongestRssi;
}

/// Why the evaluator (dis)allowed a transition — for telemetry/debugging while
/// auto-fire is disabled, and for future false-positive analysis.
enum AutoTransitionReason {
  eligible,
  notOutdoor,
  transitionInFlight,
  alreadyFired,
  noIndoorDestination,
  indoorPathNotReady,
  outOfRange,
  weakBeacon,
}

/// The evaluator's per-instant verdict.
class AutoTransitionDecision {
  const AutoTransitionDecision(this.eligible, this.reason);

  final bool eligible;
  final AutoTransitionReason reason;
}

/// Pure evaluator. Applies the transition guards in order and returns the
/// first failing reason, or [AutoTransitionReason.eligible].
class AutoTransitionEvaluator {
  const AutoTransitionEvaluator({
    this.config = const AutoTransitionConfig(),
  });

  final AutoTransitionConfig config;

  AutoTransitionDecision evaluate(AutoTransitionInputs i) {
    if (!i.isOutdoor) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.notOutdoor,
      );
    }

    if (!i.transitionIdle) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.transitionInFlight,
      );
    }

    if (i.alreadyFired) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.alreadyFired,
      );
    }

    if (!i.hasIndoorDestination) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.noIndoorDestination,
      );
    }

    if (!i.indoorPathReady) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.indoorPathNotReady,
      );
    }

    final distance = i.distanceToEntranceMeters;
    if (distance == null || distance > config.entranceRadiusMeters) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.outOfRange,
      );
    }

    final rssi = i.strongestRssi;
    if (rssi == null || rssi < config.minBeaconRssi) {
      return const AutoTransitionDecision(
        false,
        AutoTransitionReason.weakBeacon,
      );
    }

    return const AutoTransitionDecision(
      true,
      AutoTransitionReason.eligible,
    );
  }
}
