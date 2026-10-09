import 'package:flutter/material.dart';

import '../../reviews/presentation/vendor_reviews_screen.dart';
import '../../subscription/presentation/billing_history_screen.dart';
import '../../support/presentation/support_tickets_screen.dart';
import 'vendor_gallery_screen.dart';
import 'vendor_packages_screen.dart';
import 'vendor_referrals_screen.dart';
import 'vendor_settings_screen.dart';
import 'widgets/icon_grid_menu.dart';

/// "More" bottom-nav destination - grouped shortcut tiles for everything
/// that doesn't earn its own bottom-nav slot. A single "Account Settings"
/// section holds every tile (Reviews/Support/Referrals don't have a more
/// specific home of their own in the new 4-tab layout, so they live here
/// rather than disappearing entirely or each getting their own one-tile
/// section).
class VendorMoreScreen extends StatelessWidget {
  const VendorMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GroupedIconGridMenu(
      sections: [
        IconGridSection(
          title: 'Account Settings',
          items: [
            IconGridItem(
              icon: Icons.inventory_2_outlined,
              label: 'Packages',
              tint: iconGridPalette[0],
              builder: (_) => const VendorPackagesScreen(),
            ),
            IconGridItem(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              tint: iconGridPalette[1],
              builder: (_) => const VendorGalleryScreen(),
            ),
            IconGridItem(
              icon: Icons.star_outline,
              label: 'Reviews',
              tint: iconGridPalette[5],
              builder: (_) => const VendorReviewsScreen(),
            ),
            IconGridItem(
              icon: Icons.settings_outlined,
              label: 'Account Settings',
              tint: iconGridPalette[6],
              builder: (_) => const VendorSettingsScreen(),
            ),
            IconGridItem(
              icon: Icons.support_agent_outlined,
              label: 'Support',
              tint: iconGridPalette[2],
              builder: (_) => const SupportTicketsScreen(),
              hasOwnAppBar: true,
            ),
            IconGridItem(
              icon: Icons.card_giftcard_outlined,
              label: 'Referrals',
              tint: iconGridPalette[4],
              builder: (_) => const VendorReferralsScreen(),
            ),
            IconGridItem(
              icon: Icons.receipt_long_outlined,
              label: 'Billing and Subscription',
              tint: iconGridPalette[3],
              builder: (_) => const BillingHistoryScreen(),
              hasOwnAppBar: true,
            ),
          ],
        ),
      ],
    );
  }
}
