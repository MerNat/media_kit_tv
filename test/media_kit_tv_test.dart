import 'package:flutter_test/flutter_test.dart';

/// Mirrors the acceleration logic from MaterialTvSeekBarState.
/// multiplier = (1 + repeatCount ~/ accelThreshold).clamp(1, maxAccelMultiplier)
int seekMultiplier(int repeatCount,
    {int accelThreshold = 4, int maxAccelMultiplier = 6}) {
  return (1 + repeatCount ~/ accelThreshold).clamp(1, maxAccelMultiplier);
}

/// Computes the seek step as a fraction of total duration.
/// Returns the percentage (0.0–1.0) that one key event would move.
double seekStepPercent({
  required int repeatCount,
  required Duration baseSeek,
  required Duration totalDuration,
  int accelThreshold = 4,
  int maxAccelMultiplier = 6,
}) {
  if (totalDuration.inMilliseconds <= 0) return 0.0;
  final multiplier = seekMultiplier(repeatCount,
      accelThreshold: accelThreshold, maxAccelMultiplier: maxAccelMultiplier);
  final seekMs = baseSeek.inMilliseconds * multiplier;
  return seekMs / totalDuration.inMilliseconds;
}

/// Simulates a sequence of key events and returns the final slider position.
double simulateSeekSequence({
  required int eventCount,
  required int direction, // 1 for right, -1 for left
  required Duration baseSeek,
  required Duration totalDuration,
  double startPosition = 0.0,
  int accelThreshold = 4,
  int maxAccelMultiplier = 6,
}) {
  double position = startPosition;
  for (int i = 0; i < eventCount; i++) {
    final step = seekStepPercent(
      repeatCount: i,
      baseSeek: baseSeek,
      totalDuration: totalDuration,
      accelThreshold: accelThreshold,
      maxAccelMultiplier: maxAccelMultiplier,
    );
    position = (position + direction * step).clamp(0.0, 1.0);
  }
  return position;
}

void main() {
  group('Seek acceleration multiplier', () {
    test('first press has multiplier 1', () {
      expect(seekMultiplier(0), 1);
    });

    test('repeats 0-3 stay at multiplier 1', () {
      for (int i = 0; i < 4; i++) {
        expect(seekMultiplier(i), 1, reason: 'repeat $i should be 1x');
      }
    });

    test('repeats 4-7 give multiplier 2', () {
      for (int i = 4; i < 8; i++) {
        expect(seekMultiplier(i), 2, reason: 'repeat $i should be 2x');
      }
    });

    test('repeats 8-11 give multiplier 3', () {
      for (int i = 8; i < 12; i++) {
        expect(seekMultiplier(i), 3, reason: 'repeat $i should be 3x');
      }
    });

    test('multiplier caps at maxAccelMultiplier (6)', () {
      // At repeat 20: 1 + 20/4 = 6 → capped at 6
      expect(seekMultiplier(20), 6);
      // At repeat 100: 1 + 100/4 = 26 → capped at 6
      expect(seekMultiplier(100), 6);
    });

    test('custom accelThreshold changes acceleration pace', () {
      // With threshold 2: repeats 0-1 → 1x, 2-3 → 2x, 4-5 → 3x
      expect(seekMultiplier(0, accelThreshold: 2), 1);
      expect(seekMultiplier(1, accelThreshold: 2), 1);
      expect(seekMultiplier(2, accelThreshold: 2), 2);
      expect(seekMultiplier(4, accelThreshold: 2), 3);
    });

    test('custom maxAccelMultiplier changes cap', () {
      expect(seekMultiplier(20, maxAccelMultiplier: 3), 3);
      expect(seekMultiplier(20, maxAccelMultiplier: 10), 6);
    });
  });

  group('Seek step percent', () {
    test('10s base on 1-hour content gives correct step', () {
      final step = seekStepPercent(
        repeatCount: 0,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
      );
      // 10s / 3600s ≈ 0.00278
      expect(step, closeTo(10 / 3600, 0.0001));
    });

    test('accelerated step at 2x multiplier', () {
      final step = seekStepPercent(
        repeatCount: 4, // triggers 2x
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
      );
      // 20s / 3600s ≈ 0.00556
      expect(step, closeTo(20 / 3600, 0.0001));
    });

    test('max acceleration on 2-hour movie', () {
      final step = seekStepPercent(
        repeatCount: 100, // triggers max 6x
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 2),
      );
      // 60s / 7200s ≈ 0.00833
      expect(step, closeTo(60 / 7200, 0.0001));
    });

    test('zero duration returns 0', () {
      final step = seekStepPercent(
        repeatCount: 0,
        baseSeek: const Duration(seconds: 10),
        totalDuration: Duration.zero,
      );
      expect(step, 0.0);
    });
  });

  group('Seek sequence simulation', () {
    test('single tap on 1-hour content seeks ~10s', () {
      final pos = simulateSeekSequence(
        eventCount: 1,
        direction: 1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
      );
      // 10s / 3600s
      expect(pos, closeTo(10 / 3600, 0.0001));
    });

    test('holding right for 20 events covers significant distance', () {
      final pos = simulateSeekSequence(
        eventCount: 20,
        direction: 1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
      );
      // Should cover much more than 20 * 10s / 3600s because of acceleration
      final noAccelPos = 20 * 10 / 3600;
      expect(pos, greaterThan(noAccelPos));
    });

    test('holding right never resets to start', () {
      // Each successive event should move further from start, never backward
      double prev = 0.0;
      for (int i = 0; i < 30; i++) {
        final pos = simulateSeekSequence(
          eventCount: i + 1,
          direction: 1,
          baseSeek: const Duration(seconds: 10),
          totalDuration: const Duration(hours: 1),
        );
        expect(pos, greaterThanOrEqualTo(prev),
            reason: 'position should never decrease at event $i');
        prev = pos;
      }
    });

    test('left seek from middle moves backward', () {
      final pos = simulateSeekSequence(
        eventCount: 5,
        direction: -1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
        startPosition: 0.5,
      );
      expect(pos, lessThan(0.5));
    });

    test('left seek clamps at 0', () {
      final pos = simulateSeekSequence(
        eventCount: 1000,
        direction: -1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(minutes: 5),
        startPosition: 0.1,
      );
      expect(pos, 0.0);
    });

    test('right seek clamps at 1', () {
      final pos = simulateSeekSequence(
        eventCount: 1000,
        direction: 1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(minutes: 5),
        startPosition: 0.9,
      );
      expect(pos, 1.0);
    });

    test('acceleration resets between sequences', () {
      // First sequence: 4 events
      final pos1 = simulateSeekSequence(
        eventCount: 4,
        direction: 1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
      );
      // Second sequence also 4 events should give same result
      // (simulating reset by starting a new sequence)
      final pos2 = simulateSeekSequence(
        eventCount: 4,
        direction: 1,
        baseSeek: const Duration(seconds: 10),
        totalDuration: const Duration(hours: 1),
      );
      expect(pos1, pos2);
    });
  });

  group('Comparison: old vs new behavior', () {
    test('old 1% seek on 30min show = 18s, new default = 10s (more precise)',
        () {
      // Old: 1% of 30min = 18s
      const oldStepSeconds = 30 * 60 * 0.01; // 18s
      // New: fixed 10s
      const newStepSeconds = 10;
      expect(newStepSeconds, lessThan(oldStepSeconds));
    });

    test('old 1% seek on 3hr movie = 108s (too much), new = 10s', () {
      // Old: 1% of 3hr = 108s
      const oldStepSeconds = 3 * 3600 * 0.01; // 108s
      // New: fixed 10s (consistent regardless of content length)
      const newStepSeconds = 10;
      expect(newStepSeconds, lessThan(oldStepSeconds));
      expect(oldStepSeconds, greaterThan(100)); // way too much
    });
  });
}
