import 'dart:math';

import 'package:eventsrus_ui/core/config/app_config.dart';
import 'package:eventsrus_ui/core/network/api_exception.dart';
import 'package:eventsrus_ui/core/storage/secure_token_storage.dart';
import 'package:eventsrus_ui/features/auth/data/apple_auth_gateway.dart';
import 'package:eventsrus_ui/features/auth/data/auth_api.dart';
import 'package:eventsrus_ui/features/auth/data/models/apple_auth_request.dart';
import 'package:eventsrus_ui/features/auth/data/models/auth_response.dart';
import 'package:eventsrus_ui/features/auth/data/models/signup_intent.dart';
import 'package:eventsrus_ui/features/auth/presentation/login_screen.dart';
import 'package:eventsrus_ui/features/auth/state/auth_controller.dart';
import 'package:eventsrus_ui/features/notifications/data/device_token_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAuthApi implements AuthApi {
  AppleAuthRequest? received;
  Object? failWith;

  @override
  Future<AuthResponse> authenticateWithApple(AppleAuthRequest request) async {
    received = request;
    if (failWith != null) throw failWith!;
    throw StateError('not needed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused implements SecureTokenStorage, DeviceTokenApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthController _controller(_FakeAuthApi api) =>
    AuthController(authApi: api, storage: _Unused(), deviceTokenApi: _Unused());

Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AuthController>.value(
    value: _controller(_FakeAuthApi()),
    child: const MaterialApp(home: LoginScreen(intent: SignupIntent.planner)),
  ));
  await tester.pump();
}

void main() {
  group('nonce', () {
    test('is random, URL-safe and long enough', () {
      final a = AppleAuthGateway.generateNonce();
      final b = AppleAuthGateway.generateNonce();
      expect(a, isNot(b));
      expect(a.length, greaterThanOrEqualTo(40));
      expect(a, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });

    test('the digest sent to Apple is the SHA-256 hex of the raw value (what the backend recomputes)', () {
      expect(
        AppleAuthGateway.sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('a seeded generator is deterministic', () {
      expect(AppleAuthGateway.generateNonce(Random(1)), AppleAuthGateway.generateNonce(Random(1)));
    });
  });

  test('request JSON matches the backend and leaves out what Apple did not send', () {
    const full = AppleAuthRequest(
      identityToken: 't',
      nonce: 'n',
      authorizationCode: 'c',
      givenName: 'Ian',
      familyName: 'Orozco',
      intent: 'VENDOR',
    );
    expect(full.toJson(), {
      'identityToken': 't',
      'nonce': 'n',
      'authorizationCode': 'c',
      'givenName': 'Ian',
      'familyName': 'Orozco',
      'intent': 'VENDOR',
    });
    expect(const AppleAuthRequest(identityToken: 't', nonce: 'n').toJson(), {'identityToken': 't', 'nonce': 'n'});
  });

  test('a failed Apple login keeps the server message and rethrows, like Google login', () async {
    final api = _FakeAuthApi()..failWith = const ApiException(statusCode: 401, message: 'Invalid Apple identity token');
    final controller = _controller(api);

    await expectLater(
      controller.completeAppleLogin(const AppleAuthRequest(identityToken: 't', nonce: 'n')),
      throwsA(isA<ApiException>()),
    );
    expect(controller.errorMessage, 'Invalid Apple identity token');
    expect(controller.isLoading, isFalse);
    expect(api.received?.nonce, 'n');
  });

  testWidgets('iPhone shows Sign in with Apple next to Google', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pumpLogin(tester);
      expect(find.byKey(const Key('apple-sign-in')), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android does not show Sign in with Apple (unchanged login screen)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _pumpLogin(tester);
      expect(find.byKey(const Key('apple-sign-in')), findsNothing);
      expect(find.text('Sign in with Google'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('the Google iOS client id is only ever used on iOS and is empty in the test build', () {
    expect(AppConfig.googleIosClientId, isNull);
  });
}
