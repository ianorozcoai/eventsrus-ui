import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

import '../../../core/config/app_config.dart';
import 'models/billing_source.dart';

/// Which app store the in-app subscription is bought from on this device, and
/// the words / links that go with it.
class StoreInfo {
  /// Store name as shown to the person ("Google Play", "App Store").
  final String name;

  /// What the backend records as the billing source for a purchase made here.
  final BillingSource billingSource;

  /// The store's own page for managing / cancelling this app's subscription.
  final Uri manageSubscriptionUri;

  const StoreInfo._(this.name, this.billingSource, this.manageSubscriptionUri);

  bool get isApple => billingSource == BillingSource.appStore;

  static StoreInfo forPlatform([TargetPlatform? platform]) {
    if ((platform ?? defaultTargetPlatform) == TargetPlatform.iOS) return apple;
    return google;
  }

  static final StoreInfo google = StoreInfo._(
    'Google Play',
    BillingSource.googlePlay,
    Uri.https('play.google.com', '/store/account/subscriptions', {
      'sku': AppConfig.playSubscriptionId,
      'package': AppConfig.androidPackageName,
    }),
  );

  // Apple's page listing every subscription of the signed-in Apple ID.
  static final StoreInfo apple = StoreInfo._(
    'App Store',
    BillingSource.appStore,
    Uri.https('apps.apple.com', '/account/subscriptions'),
  );
}
