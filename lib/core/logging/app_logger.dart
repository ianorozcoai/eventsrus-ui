import 'dart:developer' as developer;

/// Thin facade over dart:developer's log() - gives every catch block/error
/// hook in the app one place to report through, visible in `flutter run`/
/// DevTools output, instead of the exception just being discarded. No new
/// dependency: this ships with the Flutter SDK. If a real crash-reporting
/// backend (Crashlytics/Sentry) is added later, this is the only file that
/// needs to change.
class AppLogger {
  AppLogger._();

  static void error(String area, String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: area, error: error, stackTrace: stackTrace, level: 1000);
  }

  static void warn(String area, String message) {
    developer.log(message, name: area, level: 900);
  }
}
