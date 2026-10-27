import 'package:eventsrus_ui/features/subscription/data/models/billing_source.dart';
import 'package:eventsrus_ui/features/subscription/data/store_info.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android buys from Google Play and manages there', () {
    final store = StoreInfo.forPlatform(TargetPlatform.android);
    expect(store.name, 'Google Play');
    expect(store.billingSource, BillingSource.googlePlay);
    expect(store.isApple, isFalse);
    expect(store.manageSubscriptionUri.host, 'play.google.com');
    expect(store.manageSubscriptionUri.queryParameters['package'], 'com.eventsrus.eventsrus_ui');
  });

  test('iOS buys from the App Store and manages there', () {
    final store = StoreInfo.forPlatform(TargetPlatform.iOS);
    expect(store.name, 'App Store');
    expect(store.billingSource, BillingSource.appStore);
    expect(store.isApple, isTrue);
    expect(store.manageSubscriptionUri.host, 'apps.apple.com');
  });
}
