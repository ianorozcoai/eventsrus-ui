import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/models/business_type.dart';
import '../../marketplace/data/models/vendor_public_profile.dart';
import '../../marketplace/data/vendor_directory_api.dart';
import '../../marketplace/presentation/storefront_sections.dart';
import '../../reviews/presentation/review_dialog.dart';
import '../data/vendor_settings_api.dart';

/// "My Page" bottom-nav destination - the vendor's own public storefront,
/// read back exactly the way a planner browsing the marketplace would see
/// it (same GET /api/v1/vendors/{slug} a planner hits, see
/// VendorDirectoryApi.getProfile) and covering the same real sections as
/// eventsrus-web's vendor/storefront.html: gallery, packages, reviews,
/// contact/social links, payment methods, and legal/verification documents.
/// Laid out as native scrollable sections/chips rather than that page's
/// hero banner + sidebar + Bootstrap tabs, to read as a mobile screen
/// rather than a shrunk desktop page. Read-only, same reasoning as
/// VendorReviewsScreen: eventsrus-web has no separate "edit storefront"
/// surface either - the vendor edits the underlying fields on the Settings
/// tabs (business info, packages, gallery) and this just previews the
/// result.
class VendorStorefrontScreen extends StatefulWidget {
  const VendorStorefrontScreen({super.key});

  @override
  State<VendorStorefrontScreen> createState() => _VendorStorefrontScreenState();
}

class _VendorStorefrontScreenState extends State<VendorStorefrontScreen> {
  VendorPublicProfile? _profile;
  bool _loading = true;
  bool _failed = false;
  bool _noSlugYet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _noSlugYet = false;
    });
    try {
      final settings = await context.read<VendorSettingsApi>().getSettings();
      final slug = settings.slug;
      if (slug == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _noSlugYet = true;
        });
        return;
      }
      final profile = await context.read<VendorDirectoryApi>().getProfile(slug);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_noSlugYet) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Finish onboarding to publish your storefront.')),
            ),
          ],
        ),
      );
    }
    final profile = _profile;
    if (_failed || profile == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Could not load your storefront. Pull to retry.')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: profile.logoImageUrl != null ? NetworkImage(profile.logoImageUrl!) : null,
                child: profile.logoImageUrl == null ? const Icon(Icons.storefront_outlined, size: 28) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.businessName ?? 'Your storefront',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (profile.identityVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Colors.green, size: 18),
                        ],
                      ],
                    ),
                    if (profile.businessTypes.isNotEmpty)
                      Text(
                        profile.businessTypes.map(BusinessTypeApi.labelOrRaw).join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    if ([profile.city, profile.state, profile.country].any((p) => p != null && p.isNotEmpty))
                      Text(
                        [profile.city, profile.state, profile.country].where((p) => p != null && p.isNotEmpty).join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    if (profile.averageRating != null)
                      Row(
                        children: [
                          StarRatingRow(rating: profile.averageRating!, size: 16),
                          const SizedBox(width: 6),
                          Text('${profile.averageRating!.toStringAsFixed(1)} (${profile.reviewCount})',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      )
                    else
                      Text('No reviews yet', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (profile.description != null && profile.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(profile.description!),
          ],
          const SizedBox(height: 8),
          StorefrontSections(profile: profile),
        ],
      ),
    );
  }
}
