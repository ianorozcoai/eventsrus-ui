import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Google Play (Android) and the Apple App Store (iOS) both require digital
/// subscriptions bought inside the app to use their own in-app billing, and
/// forbid steering people to another payment method. Only these platforms get
/// the store-billing flow; PayPal/GCash stay on the website.
bool platformUsesStoreBilling([TargetPlatform? platform]) {
  final p = platform ?? defaultTargetPlatform;
  return p == TargetPlatform.android || p == TargetPlatform.iOS;
}
