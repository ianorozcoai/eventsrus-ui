import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import 'models/billing_cycle.dart';

/// One Google Play price the supplier can pick. [priceString] comes straight
/// from the store (already localised, e.g. "₱4,500.00") and is never
/// hard-coded or computed in the app. [handle] is whatever the gateway needs
/// to start the purchase later (the RevenueCat Package for the real one).
class PlayOffer {
  final BillingCycle cycle;
  final String priceString;
  final Object? handle;

  const PlayOffer({required this.cycle, required this.priceString, this.handle});
}

enum PlayPurchaseOutcome { purchased, cancelled }

/// Thrown when Play Billing cannot be used right now (no key in this build,
/// no store reachable, no offering set up yet). The plan screen turns it into
/// its "not available yet" state.
class PlayBillingUnavailable implements Exception {
  final String reason;
  const PlayBillingUnavailable(this.reason);

  @override
  String toString() => 'PlayBillingUnavailable: $reason';
}

/// Thin seam over purchases_flutter so the screens can be tested without a
/// store. The real one is [RevenueCatPlayBillingGateway].
abstract class PlayBillingGateway {
  /// Offers for the three supported cycles, in quarterly, semi-annual, annual
  /// order. [appUserId] is the EventsRUs backend user id: it is what ties a
  /// Play purchase to the account in RevenueCat's webhook.
  Future<List<PlayOffer>> loadOffers(String appUserId);

  Future<PlayPurchaseOutcome> purchase(PlayOffer offer);

  /// Re-attaches purchases the Google account already owns to this user.
  Future<void> restore();

  Future<void> logOut();
}

class RevenueCatPlayBillingGateway implements PlayBillingGateway {
  RevenueCatPlayBillingGateway._();
  static final RevenueCatPlayBillingGateway instance = RevenueCatPlayBillingGateway._();

  String? _loggedInAs;

  Future<void> _ensureConfigured(String appUserId) async {
    final key = AppConfig.revenueCatApiKey;
    if (key == null) {
      throw const PlayBillingUnavailable('No usable RC_API_KEY in this build');
    }
    if (!await Purchases.isConfigured) {
      await Purchases.configure(PurchasesConfiguration(key)..appUserID = appUserId);
      _loggedInAs = appUserId;
    } else if (_loggedInAs != appUserId) {
      await Purchases.logIn(appUserId);
      _loggedInAs = appUserId;
    }
  }

  @override
  Future<List<PlayOffer>> loadOffers(String appUserId) async {
    try {
      await _ensureConfigured(appUserId);
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const <Package>[];
      final offers = <PlayOffer>[];
      // The standard RevenueCat package types, so the dashboard identifiers
      // can be renamed without touching the app.
      for (final entry in const {
        PackageType.threeMonth: BillingCycle.quarterly,
        PackageType.sixMonth: BillingCycle.semiAnnual,
        PackageType.annual: BillingCycle.annual,
      }.entries) {
        for (final p in packages) {
          if (p.packageType == entry.key) {
            offers.add(PlayOffer(cycle: entry.value, priceString: p.storeProduct.priceString, handle: p));
            break;
          }
        }
      }
      return offers;
    } on PlayBillingUnavailable {
      rethrow;
    } on PlatformException catch (e) {
      AppLogger.error('PlayBilling', 'Could not load offerings', error: e);
      throw PlayBillingUnavailable(e.message ?? 'store error');
    }
  }

  @override
  Future<PlayPurchaseOutcome> purchase(PlayOffer offer) async {
    try {
      await Purchases.purchase(PurchaseParams.package(offer.handle! as Package));
      return PlayPurchaseOutcome.purchased;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        return PlayPurchaseOutcome.cancelled;
      }
      rethrow;
    }
  }

  @override
  Future<void> restore() async {
    if (await Purchases.isConfigured) {
      await Purchases.restorePurchases();
    }
  }

  @override
  Future<void> logOut() async {
    _loggedInAs = null;
    try {
      if (await Purchases.isConfigured) {
        await Purchases.logOut();
      }
    } catch (_) {
      // Best effort, same as the rest of logout: never block signing out.
    }
  }
}
