import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../marketplace/data/models/vendor_legal_document.dart';
import '../../marketplace/data/models/vendor_package.dart';
import '../../marketplace/data/models/vendor_public_profile.dart';
import '../../marketplace/data/vendor_directory_api.dart';
import '../../marketplace/presentation/lifecycle_widgets.dart';
import '../../reviews/data/models/review.dart';
import '../../reviews/presentation/review_dialog.dart';
import '../../reviews/presentation/vendor_reviews_screen.dart';
import '../data/models/legal_document_type.dart';
import '../data/models/social_media_platform.dart';
import '../data/models/vendor_payment_method.dart';
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

  String _galleryFilter = 'All';
  String _packageFilter = 'All';

  // Shown in place of the main list (not a modal/bottom sheet) when set -
  // a modal route always overlays the whole screen, including VendorShell's
  // own header and bottom nav bar above this tab's body, which read as a
  // dead end with no way back. Rendering it as this screen's own body
  // instead keeps that chrome visible and gives it a normal in-page back
  // button.
  VendorPackage? _selectedPackage;

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
      _galleryFilter = 'All';
      _packageFilter = 'All';
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
    final selectedPackage = _selectedPackage;
    if (selectedPackage != null) {
      // Intercepts the Android back button/gesture too, not just the
      // in-page IconButton - otherwise it would pop this tab's whole route
      // instead of just clearing the selection.
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) setState(() => _selectedPackage = null);
        },
        child: _buildPackageDetail(selectedPackage),
      );
    }
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

    final filteredGallery = _galleryFilter == 'All'
        ? profile.galleryImages
        : profile.galleryImages.where((img) => img.tags.contains(_galleryFilter)).toList();
    final filteredPackages = _packageFilter == 'All'
        ? profile.packages
        : profile.packages.where((pkg) => pkg.groups.contains(_packageFilter)).toList();

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

          if (profile.galleryImages.isNotEmpty) ...[
            const _SectionHeader('Gallery'),
            if (profile.availableImageTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FilterChipRow(
                options: ['All', ...profile.availableImageTags],
                selected: _galleryFilter,
                onSelected: (v) => setState(() => _galleryFilter = v),
              ),
            ],
            const SizedBox(height: 8),
            if (filteredGallery.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No photos tagged with this yet.'),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGallery.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onTap: () => _showImageViewer(context, filteredGallery[i].imageUrl),
                    child: Image.network(filteredGallery[i].imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
          ],

          const _SectionHeader('Packages'),
          if (profile.availableGroups.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FilterChipRow(
              options: ['All', ...profile.availableGroups],
              selected: _packageFilter,
              onSelected: (v) => setState(() => _packageFilter = v),
            ),
          ],
          const SizedBox(height: 8),
          if (filteredPackages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                profile.packages.isEmpty ? 'No packages published yet.' : 'No packages grouped under this yet.',
              ),
            )
          else
            for (final package in filteredPackages)
              _PackageCard(package: package, onTap: () => setState(() => _selectedPackage = package)),

          if (profile.reviews.isNotEmpty) ...[
            const _SectionHeader('Client Reviews'),
            const SizedBox(height: 8),
            for (final review in profile.reviews.take(2)) _ReviewPreviewCard(review: review),
            if (profile.reviews.length > 2)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VendorReviewsScreen())),
                  child: Text('View all ${profile.reviews.length} reviews'),
                ),
              ),
          ],

          const _SectionHeader('Contact'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.contactEmail != null) _ContactRow(icon: Icons.alternate_email, text: profile.contactEmail!),
                  if (profile.phoneNumber != null) _ContactRow(icon: Icons.phone_outlined, text: profile.phoneNumber!),
                  for (final link in profile.socialMediaLinks)
                    _ContactRow(
                      icon: link.platform.icon,
                      text: link.url,
                      onTap: () => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
                    ),
                ],
              ),
            ),
          ),

          if (profile.paymentInstructions != null && profile.paymentInstructions!.isNotEmpty ||
              profile.paymentMethods.isNotEmpty) ...[
            const _SectionHeader('Payment Methods'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.paymentInstructions != null && profile.paymentInstructions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(profile.paymentInstructions!),
                      ),
                    if (profile.paymentMethods.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [for (final method in profile.paymentMethods) _PaymentMethodTile(method: method)],
                      ),
                  ],
                ),
              ),
            ),
          ],

          if (profile.legalDocuments.isNotEmpty) ...[
            const _SectionHeader('Verification & Legalities'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [for (final doc in profile.legalDocuments) _LegalDocumentTile(document: doc)],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Package detail - badge/price/description/photos, same content as
  /// eventsrus-web's per-package modal (vendor/storefront.html). Rendered
  /// as this screen's own body (see _selectedPackage's doc comment above)
  /// rather than a modal sheet, so VendorShell's header and bottom nav
  /// bar stay visible and there's a normal in-page back button. Each photo
  /// opens in [_showImageViewer] on tap.
  Widget _buildPackageDetail(VendorPackage package) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to packages',
                onPressed: () => setState(() => _selectedPackage = null),
              ),
              const SizedBox(width: 4),
              Text('Package details', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Chip(
            label: Text(package.packageType.label),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 8),
          Text(
            package.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_packagePriceLabel(package) ?? '', style: Theme.of(context).textTheme.titleMedium),
          if (package.description != null && package.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(package.description!),
          ],
          if (package.images.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Photos', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: package.images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onTap: () => _showImageViewer(context, package.images[i].imageUrl),
                  child: Image.network(package.images[i].imageUrl, fit: BoxFit.cover),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Text('No photos for this package yet.'),
          ],
        ],
      ),
    );
  }
}

/// Full-screen pinch-to-zoom viewer - used by the gallery grid, a tapped
/// package detail photo, and a tapped payment-method QR code, so all three
/// get the same zoom behavior from one place. Kept as a dialog (unlike the
/// package detail above) - a quick full-screen photo lightbox is expected
/// to cover everything, same as eventsrus-web's own lightbox.
void _showImageViewer(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: InteractiveViewer(child: Image.network(imageUrl)),
    ),
  );
}

String? _packagePriceLabel(VendorPackage package) => switch (package.pricingType) {
      PackagePricingType.fixed => package.price != null ? formatPeso(package.price!) : null,
      PackagePricingType.range => (package.minPrice != null && package.maxPrice != null)
          ? '${formatPeso(package.minPrice!)} - ${formatPeso(package.maxPrice!)}'
          : null,
      PackagePricingType.quote => 'Request for Quotation',
    };

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChipRow({required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _ContactRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final VendorPaymentMethod method;

  const _PaymentMethodTile({required this.method});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          if (method.qrImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _showImageViewer(context, method.qrImageUrl!),
                child: Image.network(method.qrImageUrl!, width: 90, height: 90, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code),
            ),
          const SizedBox(height: 6),
          Text(method.label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LegalDocumentTile extends StatelessWidget {
  final VendorLegalDocument document;

  const _LegalDocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Legal documents are always images here (upload is restricted to
      // FileType.image - see vendor_onboarding_screen.dart), so this opens
      // the same in-app zoom viewer as the gallery/package photos/QR codes
      // instead of launching an external browser.
      onTap: () => _showImageViewer(context, document.url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(height: 6),
            Text(
              document.label ?? document.documentType.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPreviewCard extends StatelessWidget {
  final Review review;

  const _ReviewPreviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            const SizedBox(height: 6),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final VendorPackage package;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceLabel = _packagePriceLabel(package);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.images.isNotEmpty)
              Image.network(package.images.first.imageUrl, width: 88, height: 88, fit: BoxFit.cover)
            else
              Container(
                width: 88,
                height: 88,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.inventory_2_outlined),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (priceLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(priceLabel, style: Theme.of(context).textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12, top: 12),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
