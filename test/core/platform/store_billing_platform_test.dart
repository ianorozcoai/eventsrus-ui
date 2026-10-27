import 'package:eventsrus_ui/core/platform/store_billing_platform.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android and iOS must use store billing', () {
    expect(platformUsesStoreBilling(TargetPlatform.android), isTrue);
    expect(platformUsesStoreBilling(TargetPlatform.iOS), isTrue);
  });

  test('other platforms do not', () {
    for (final p in [TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.fuchsia]) {
      expect(platformUsesStoreBilling(p), isFalse, reason: '$p');
    }
  });
}
