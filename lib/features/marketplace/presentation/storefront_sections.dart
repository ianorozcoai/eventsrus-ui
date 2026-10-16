import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../moderation/data/moderation_models.dart';
import '../../moderation/presentation/moderation_actions.dart';
import '../../reviews/data/models/review.dart';
import '../../reviews/presentation/review_dialog.dart';
import '../../reviews/presentation/vendor_reviews_screen.dart';
import '../../vendor/data/models/legal_document_type.dart';
import '../../vendor/data/models/social_media_platform.dart';
import '../../vendor/data/models/vendor_payment_method.dart';
import '../data/models/vendor_legal_document.dart';
import '../data/models/vendor_package.dart';
import '../data/models/vendor_public_profile.dart';
import 'attachment_viewer.dart';
import 'lifecycle_widgets.dart';

/// Gallery, Packages (with per-package detail view), Client Reviews,
/// Contact, Payment Methods and Verification & Legalities - the sections
/// shared by every read-only view of a [VendorPublicProfile]: the vendor's
/// own "My Page" preview (vendor_storefront_screen.dart) and the
/// planner-facing storefront (vendor_profile_screen.dart). Both show the
/// exact same data (same GET /api/v1/vendors/{slug}), so this is one
/// widget instead of two near-duplicates. Returns a plain Column, not its
/// own Scaffold/scrollable - the host screen provides the outer scroll
/// view (and its own header/description/action buttons, which differ
/// between the two hosts and so stay out of this shared widget).
class StorefrontSections extends StatefulWidget {
  final VendorPublicProfile profile;

  const StorefrontSections({super.key, required this.profile});

  @override
  State<StorefrontSections> createState() => _StorefrontSectionsState();
}

class _StorefrontSectionsState extends State<StorefrontSections> {
  String _galleryFilter = 'All';
  String _packageFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final filteredGallery = _galleryFilter == 'All'
        ? profile.galleryImages
        : profile.galleryImages.where((img) => img.tags.contains(_galleryFilter)).toList();
    final filteredPackages = _packageFilter == 'All'
        ? profile.packages
        : profile.packages.where((pkg) => pkg.groups.contains(_packageFilter)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  onTap: () => showImageViewer(context, filteredGallery[i].imageUrl),
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
            _PackageCard(
              package: package,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _PackageDetailScreen(package: package)),
              ),
            ),

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
    );
  }

}

/// Package detail - badge/price/description/photos, same content as
/// eventsrus-web's per-package modal (vendor/storefront.html). Pushed as
/// its own full screen (not an in-page swap) so it shows only the package,
/// not the host storefront's own header/action buttons still sitting above
/// it. Each photo opens the shared [showImageViewer] lightbox on tap.
class _PackageDetailScreen extends StatelessWidget {
  final VendorPackage package;

  const _PackageDetailScreen({required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(package.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    onTap: () => showImageViewer(context, package.images[i].imageUrl),
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
      ),
    );
  }
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
                onTap: () => showImageViewer(context, method.qrImageUrl!),
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
      onTap: () => showImageViewer(context, document.url),
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
                // Report a review (Google Play: users must be able to flag content).
                // Only a note to the admin; nothing is hidden by it.
                PopupMenuButton<String>(
                  tooltip: 'More',
                  padding: EdgeInsets.zero,
                  onSelected: (_) => reportWithDialog(
                    context,
                    contentType: ReportContentType.review,
                    contentId: review.id,
                    subject: 'this review',
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'report', child: Text('Report this review')),
                  ],
                ),
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
