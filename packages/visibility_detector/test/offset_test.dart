// Tests for the `offset` (shift semantics) parameter on VisibilityDetector.
//
// These tests validate that:
//  * A widget completely outside the clipped viewport does NOT trigger a
//    visibility callback (baseline, no offset).
//  * The same geometry with a negative shift along the primary axis DOES
//    trigger a visibility callback earlier (partial visibleFraction > 0).
//  * Horizontal and vertical shifting behave analogously.
//  * The reported visibleFraction corresponds to the portion shifted into view
//    relative to the real widget size (shift does not change size).
//
// NOTE: We intentionally rely on the implementation detail that invisible
// widgets with no previous visibility state do not fire callbacks.
//
// Copyright 2018 the Dart project authors.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  // Immediate callbacks for deterministic expectations.
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('Shift offset enables early vertical detection', (tester) async {
    VisibilityInfo? noOffsetInfo;
    VisibilityInfo? withOffsetInfo;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: ClipRect(
              child: Stack(
                children: [
                  // Positioned fully below the clipped 120x120 area (top: 150).
                  Positioned(
                    top: 150,
                    left: 0,
                    child: VisibilityDetector(
                      key: const Key('no_offset'),
                      onVisibilityChanged: (info) {
                        noOffsetInfo = info;
                      },
                      child: const SizedBox(width: 50, height: 50),
                    ),
                  ),
                  // Same geometry but shifted upward by 60 pixels before
                  // intersection; top becomes 90 => 30px visible (30/50 = 0.6).
                  Positioned(
                    top: 150,
                    left: 60,
                    child: VisibilityDetector(
                      key: const Key('with_offset'),
                      offset: const Offset(0, -60),
                      onVisibilityChanged: (info) {
                        withOffsetInfo = info;
                      },
                      child: const SizedBox(width: 50, height: 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Invisible widget: no callback fired yet.
    expect(noOffsetInfo, isNull);

    // Shifted widget: partial visibility callback fired.
    expect(withOffsetInfo, isNotNull);
    expect(withOffsetInfo!.size, const Size(50, 50));
    // Expect ~60% (30 / 50) visible. Allow a small epsilon.
    expect(
        withOffsetInfo!.visibleFraction, moreOrLessEquals(0.6, epsilon: 0.01));
    // Visible bounds height should be close to 30.
    expect(withOffsetInfo!.visibleBounds.height,
        moreOrLessEquals(30, epsilon: 0.5));
  });

  testWidgets('Shift offset enables early horizontal detection',
      (tester) async {
    VisibilityInfo? noOffsetInfo;
    VisibilityInfo? withOffsetInfo;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: ClipRect(
              child: Stack(
                children: [
                  // Positioned fully to the right of the clip (left: 150).
                  Positioned(
                    top: 0,
                    left: 150,
                    child: VisibilityDetector(
                      key: const Key('no_offset_h'),
                      onVisibilityChanged: (info) {
                        noOffsetInfo = info;
                      },
                      child: const SizedBox(width: 50, height: 50),
                    ),
                  ),
                  // Shift left by 60 => left becomes 90 => 30 px visible (30/50 = 0.6).
                  Positioned(
                    top: 60,
                    left: 150,
                    child: VisibilityDetector(
                      key: const Key('with_offset_h'),
                      offset: const Offset(-60, 0),
                      onVisibilityChanged: (info) {
                        withOffsetInfo = info;
                      },
                      child: const SizedBox(width: 50, height: 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(noOffsetInfo, isNull);
    expect(withOffsetInfo, isNotNull);
    expect(withOffsetInfo!.size, const Size(50, 50));
    expect(
        withOffsetInfo!.visibleFraction, moreOrLessEquals(0.6, epsilon: 0.01));
    expect(withOffsetInfo!.visibleBounds.width,
        moreOrLessEquals(30, epsilon: 0.5));
  });

  testWidgets('Shift does not change visibleFraction for fully visible object',
      (tester) async {
    VisibilityInfo? baseline;
    VisibilityInfo? shifted;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: VisibilityDetector(
                      key: const Key('baseline_full'),
                      onVisibilityChanged: (info) => baseline = info,
                      child: const SizedBox(width: 80, height: 80),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 110,
                    child: VisibilityDetector(
                      key: const Key('shifted_full'),
                      offset: const Offset(-10, -10),
                      onVisibilityChanged: (info) => shifted = info,
                      child: const SizedBox(width: 80, height: 80),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(baseline, isNotNull);
    expect(shifted, isNotNull);
    expect(baseline!.visibleFraction, 1.0);
    expect(shifted!.visibleFraction, 1.0);
    // Shift should not alter reported size.
    expect(shifted!.size, baseline!.size);
  });
}
