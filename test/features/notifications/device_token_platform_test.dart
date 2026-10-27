import 'package:eventsrus_ui/features/notifications/data/device_token_api.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the device token is registered with the platform it came from', () {
    expect(DeviceTokenApi.platformName(TargetPlatform.iOS), 'IOS');
    expect(DeviceTokenApi.platformName(TargetPlatform.android), 'ANDROID');
  });
}
