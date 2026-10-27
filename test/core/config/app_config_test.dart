import 'package:eventsrus_ui/core/config/app_config.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backendBaseUrl falls back to localhost on the (non-Android) test host', () {
    // The --dart-define override and the Android-emulator (10.0.2.2) branch
    // both need a real build/Platform context this plain unit test doesn't
    // have - this just locks in the one branch that's actually reachable
    // here: no override set, not running as Android, so localhost.
    expect(AppConfig.backendBaseUrl, 'http://localhost:8080');
  });

  group('RevenueCat key', () {
    test('empty key means not configured', () {
      expect(AppConfig.usableRevenueCatKey('', allowTestStore: false), isNull);
      expect(AppConfig.usableRevenueCatKey('   ', allowTestStore: true), isNull);
    });

    test('a test_ key is ignored unless ALLOW_TEST_STORE is set', () {
      expect(AppConfig.usableRevenueCatKey('test_abc', allowTestStore: false), isNull);
      expect(AppConfig.usableRevenueCatKey('test_abc', allowTestStore: true), 'test_abc');
    });

    test('a public Android key is used as is', () {
      expect(AppConfig.usableRevenueCatKey('goog_abc', allowTestStore: false), 'goog_abc');
    });

    String? keyFor(TargetPlatform p, {String android = '', String ios = '', bool allowTest = false}) =>
        AppConfig.revenueCatKeyFor(p, androidKey: android, iosKey: ios, allowTestStore: allowTest);

    test('Android uses RC_API_KEY exactly as before and ignores the iOS key', () {
      expect(keyFor(TargetPlatform.android, android: 'goog_abc', ios: 'appl_xyz'), 'goog_abc');
      expect(keyFor(TargetPlatform.android, ios: 'appl_xyz'), isNull);
    });

    test('iOS uses RC_API_KEY_IOS and only accepts an appl_ key', () {
      expect(keyFor(TargetPlatform.iOS, android: 'goog_abc', ios: 'appl_xyz'), 'appl_xyz');
      expect(keyFor(TargetPlatform.iOS, android: 'goog_abc'), isNull);
      // An Android key put in the iOS slot by mistake is rejected.
      expect(keyFor(TargetPlatform.iOS, ios: 'goog_abc'), isNull);
    });

    test('iOS test_ key needs ALLOW_TEST_STORE too', () {
      expect(keyFor(TargetPlatform.iOS, ios: 'test_abc'), isNull);
      expect(keyFor(TargetPlatform.iOS, ios: 'test_abc', allowTest: true), 'test_abc');
    });

    test('no key is supplied in the test build', () {
      expect(AppConfig.revenueCatApiKey, isNull);
    });
  });

  test('googleWebClientId is the Web-application OAuth client the backend verifies against', () {
    expect(AppConfig.googleWebClientId, endsWith('.apps.googleusercontent.com'));
  });
}
