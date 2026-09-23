import 'package:flutter_test/flutter_test.dart';

import 'package:cognifind/features/navigation/transition/auto_transition_evaluator.dart';

void main() {
  const evaluator = AutoTransitionEvaluator();

  /// A fully-eligible baseline snapshot; individual tests flip one field to
  /// assert the corresponding guard fires.
  AutoTransitionInputs eligible({
    bool isOutdoor = true,
    bool transitionIdle = true,
    bool alreadyFired = false,
    bool hasIndoorDestination = true,
    bool indoorPathReady = true,
    double? distanceToEntranceMeters = 10,
    int? strongestRssi = -60,
  }) {
    return AutoTransitionInputs(
      isOutdoor: isOutdoor,
      transitionIdle: transitionIdle,
      alreadyFired: alreadyFired,
      hasIndoorDestination: hasIndoorDestination,
      indoorPathReady: indoorPathReady,
      distanceToEntranceMeters: distanceToEntranceMeters,
      strongestRssi: strongestRssi,
    );
  }

  test('eligible when all guards pass', () {
    final d = evaluator.evaluate(eligible());
    expect(d.eligible, isTrue);
    expect(d.reason, AutoTransitionReason.eligible);
  });

  test('rejects when not outdoor', () {
    final d = evaluator.evaluate(eligible(isOutdoor: false));
    expect(d.eligible, isFalse);
    expect(d.reason, AutoTransitionReason.notOutdoor);
  });

  test('rejects when a transition is already in flight', () {
    final d = evaluator.evaluate(eligible(transitionIdle: false));
    expect(d.reason, AutoTransitionReason.transitionInFlight);
  });

  test('rejects when already fired (single-fire)', () {
    final d = evaluator.evaluate(eligible(alreadyFired: true));
    expect(d.reason, AutoTransitionReason.alreadyFired);
  });

  test('rejects when there is no indoor destination', () {
    final d = evaluator.evaluate(eligible(hasIndoorDestination: false));
    expect(d.reason, AutoTransitionReason.noIndoorDestination);
  });

  test('rejects when indoor path is not preloaded', () {
    final d = evaluator.evaluate(eligible(indoorPathReady: false));
    expect(d.reason, AutoTransitionReason.indoorPathNotReady);
  });

  test('rejects when distance is unknown', () {
    final d = evaluator.evaluate(eligible(distanceToEntranceMeters: null));
    expect(d.reason, AutoTransitionReason.outOfRange);
  });

  test('rejects when beyond the entrance radius (default 15m)', () {
    final d = evaluator.evaluate(eligible(distanceToEntranceMeters: 15.1));
    expect(d.reason, AutoTransitionReason.outOfRange);
  });

  test('accepts exactly at the entrance radius boundary', () {
    final d = evaluator.evaluate(eligible(distanceToEntranceMeters: 15));
    expect(d.eligible, isTrue);
  });

  test('rejects when no beacon is seen', () {
    final d = evaluator.evaluate(eligible(strongestRssi: null));
    expect(d.reason, AutoTransitionReason.weakBeacon);
  });

  test('rejects when beacon is too weak (below -70 dBm)', () {
    final d = evaluator.evaluate(eligible(strongestRssi: -71));
    expect(d.reason, AutoTransitionReason.weakBeacon);
  });

  test('accepts exactly at the minimum RSSI boundary', () {
    final d = evaluator.evaluate(eligible(strongestRssi: -70));
    expect(d.eligible, isTrue);
  });

  test('guard order: not-outdoor takes precedence over weak beacon', () {
    final d = evaluator.evaluate(
      eligible(isOutdoor: false, strongestRssi: null),
    );
    expect(d.reason, AutoTransitionReason.notOutdoor);
  });
}
