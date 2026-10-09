import 'package:eventsrus_ui/features/auth/data/models/auth_response.dart';
import 'package:eventsrus_ui/features/auth/data/models/plan_tier.dart';
import 'package:eventsrus_ui/features/auth/data/models/role.dart';
import 'package:eventsrus_ui/features/auth/data/models/signup_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResponse.fromJson', () {
    test('parses a full vendor response with a plan', () {
      final response = AuthResponse.fromJson({
        'token': 'a.jwt.token',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'role': 'VENDOR',
        'signupIntent': 'VENDOR',
        'firstName': 'Ian',
        'email': 'vendor@example.com',
        'plan': 'PRO',
        'planExpiresAt': '2026-12-01T00:00:00Z',
      });

      expect(response.token, 'a.jwt.token');
      expect(response.role, Role.vendor);
      expect(response.signupIntent, SignupIntent.vendor);
      expect(response.plan, PlanTier.pro);
      expect(response.planExpiresAt, DateTime.parse('2026-12-01T00:00:00Z'));
    });

    test('a planner mid-vendor-onboarding has role planner but signupIntent vendor', () {
      final response = AuthResponse.fromJson({
        'token': 'a.jwt.token',
        'expiresIn': 3600,
        'role': 'PLANNER',
        'signupIntent': 'VENDOR',
      });

      expect(response.role, Role.planner);
      expect(response.signupIntent, SignupIntent.vendor);
    });

    test('defaults tokenType to Bearer and tolerates missing optional fields', () {
      final response = AuthResponse.fromJson({
        'token': 'a.jwt.token',
        'expiresIn': 3600,
        'role': 'PLANNER',
      });

      expect(response.tokenType, 'Bearer');
      expect(response.signupIntent, isNull);
      expect(response.firstName, isNull);
      expect(response.plan, isNull);
      expect(response.planExpiresAt, isNull);
    });

    test('throws on an unrecognized role rather than silently misrouting a user', () {
      expect(
        () => AuthResponse.fromJson({
          'token': 'a.jwt.token',
          'expiresIn': 3600,
          'role': 'SUPERADMIN',
        }),
        throwsFormatException,
      );
    });
  });
}
