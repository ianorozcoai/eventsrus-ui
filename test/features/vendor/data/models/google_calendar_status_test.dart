import 'package:eventsrus_ui/features/vendor/data/models/google_calendar_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoogleCalendarStatus.fromJson parses a connected response', () {
    final status = GoogleCalendarStatus.fromJson({
      'connected': true,
      'connectedAt': '2026-09-01T10:00:00Z',
    });

    expect(status.connected, isTrue);
    expect(status.connectedAt, DateTime.parse('2026-09-01T10:00:00Z'));
  });

  test('GoogleCalendarStatus.fromJson parses a disconnected response with null connectedAt', () {
    final status = GoogleCalendarStatus.fromJson({
      'connected': false,
      'connectedAt': null,
    });

    expect(status.connected, isFalse);
    expect(status.connectedAt, isNull);
  });
}
