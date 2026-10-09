import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/data/models/vendor_public_profile.dart';
import '../../marketplace/data/vendor_directory_api.dart';
import '../../marketplace/presentation/lifecycle_widgets.dart';
import '../../vendor/data/vendor_settings_api.dart';
import 'review_dialog.dart';

/// Read-only view of the reviews a vendor has received.
///
/// eventsrus-web has no dedicated vendor "reviews" page - a vendor sees
/// their reviews on the storefront preview (vendor/storefront.html), which
/// is the vendor's own public profile rendered back to them, same data a
/// planner sees. There's also no "respond to review" feature anywhere in
/// the web app, so this screen is read-only too. The backend has no
/// authenticated "list my reviews" endpoint either - the vendor's slug
/// comes from GET /api/v1/vendors/me/settings, then the reviews come off
/// the public profile at GET /api/v1/vendors/{slug} (see
/// VendorDirectoryApi.getProfile / VendorSettingsResponse#slug).
class VendorReviewsScreen extends StatefulWidget {
  const VendorReviewsScreen({super.key});

  @override
  State<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends State<VendorReviewsScreen> {
  VendorPublicProfile? _profile;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final settings = await context.read<VendorSettingsApi>().getSettings();
      final slug = settings.slug;
      if (slug == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failed = true;
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
    final profile = _profile;
    if (_failed || profile == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Could not load your reviews. Pull to retry.')),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (profile.averageRating != null) ...[
                    Text(
                      profile.averageRating!.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRatingRow(rating: profile.averageRating!, size: 20),
                        Text('${profile.reviewCount} review${profile.reviewCount != 1 ? 's' : ''}'),
                      ],
                    ),
                  ] else
                    const Text('No reviews yet.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (profile.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Reviews from planners will show up here once they leave one.')),
            )
          else
            for (final review in profile.reviews)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.reviewerName ?? 'A planner',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          StarRatingRow(rating: review.rating.toDouble()),
                        ],
                      ),
                      if (review.eventName != null || review.eventDate != null)
                        Text(
                          [
                            if (review.eventName != null) review.eventName!,
                            if (review.eventDate != null) formatDate(review.eventDate!),
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      Text(review.comment),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
