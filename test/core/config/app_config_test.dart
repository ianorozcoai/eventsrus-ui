import 'package:eventsrus_ui/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backendBaseUrl falls back to localhost on the (non-Android) test host', () {
    // The --dart-define override and the Android-emulator (10.0.2.2) branch
    // both need a real build/Platform context this plain unit test doesn't
    // have - this just locks in the one branch that's actually reachable
    // here: no override set, not running as Android, so localhost.
    expect(AppConfig.backendBaseUrl, 'http://localhost:8080');
  });

  test('googleWebClientId is the Web-application OAuth client the backend verifies against', () {
    expect(AppConfig.googleWebClientId, endsWith('.apps.googleusercontent.com'));
  });
}
