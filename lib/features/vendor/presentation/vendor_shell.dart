import 'package:flutter/material.dart';

import '../../marketplace/presentation/app_top_bar.dart';
import '../../marketplace/presentation/conversations_screen.dart';
import '../../reviews/presentation/vendor_reviews_screen.dart';
import 'vendor_bookings_screen.dart';
import 'vendor_calendar_screen.dart';
import 'vendor_customers_hub_screen.dart';
import 'vendor_dashboard_screen.dart';
import 'vendor_gallery_screen.dart';
import 'vendor_leads_screen.dart';
import 'vendor_more_screen.dart';
import 'vendor_packages_screen.dart';
import 'vendor_quotations_screen.dart';
import 'vendor_referrals_screen.dart';
import 'vendor_settings_screen.dart';
import 'vendor_storefront_screen.dart';
import '../../marketplace/presentation/brand_header_bar.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _index = 0;
  int _narrowIndex = 0;

  static const _destinations = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (icon: Icons.person_search_outlined, label: 'Leads'),
    (icon: Icons.event_available_outlined, label: 'Bookings'),
    (icon: Icons.chat_bubble_outline, label: 'Messages'),
    (icon: Icons.request_quote_outlined, label: 'Quotations'),
    (icon: Icons.calendar_month_outlined, label: 'Calendar'),
    (icon: Icons.inventory_2_outlined, label: 'Packages'),
    (icon: Icons.photo_library_outlined, label: 'Gallery'),
    (icon: Icons.star_outline, label: 'Reviews'),
    (icon: Icons.card_giftcard_outlined, label: 'Referrals'),
    (icon: Icons.settings_outlined, label: 'Account Settings'),
  ];

  static const _screens = [
    VendorDashboardScreen(),
    VendorLeadsScreen(),
    VendorBookingsScreen(),
    ConversationsScreen(),
    VendorQuotationsScreen(),
    VendorCalendarScreen(),
    VendorPackagesScreen(),
    VendorGalleryScreen(),
    VendorReviewsScreen(),
    VendorReferralsScreen(),
    VendorSettingsScreen(),
  ];

  // Phone-width bottom tabs - just 4, each a real top-level destination or a
  // grid "hub" that fans out into several screens (IconGridMenu), the same
  // pattern banking apps use for a flat "More" tab. The brand header stays
  // constant across all 4 rather than retitling per tab.
  static const _narrowDestinations = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (icon: Icons.groups_outlined, label: 'Customers'),
    (icon: Icons.storefront_outlined, label: 'My Page'),
    (icon: Icons.menu, label: 'More'),
  ];

  static const _narrowScreens = [
    VendorDashboardScreen(),
    VendorCustomersHubScreen(),
    VendorStorefrontScreen(),
    VendorMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (!isWide) {
      return Scaffold(
        appBar: const BrandHeaderBar(),
        body: SafeArea(child: _narrowScreens[_narrowIndex]),
        // Deep violet (same accent as the dashboard's stat-card icons) -
        // darker than the logo wordmark's own #A66CF8, which read as too
        // washed-out for a solid nav bar. White icons/labels on top either
        // way, same brand treatment as BrandHeaderBar's dark bar above.
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xFF5B21B6),
            indicatorColor: Colors.white.withValues(alpha: 0.25),
            iconTheme: WidgetStateProperty.resolveWith(
              (_) => const IconThemeData(color: Colors.white),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: Colors.white,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _narrowIndex,
            onDestinationSelected: (i) => setState(() => _narrowIndex = i),
            destinations: _narrowDestinations
                .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
                .toList(),
          ),
        ),
      );
    }

    final rail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      extended: true,
      minExtendedWidth: 220,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Text('E', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            const Text('EventsRUs', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      destinations: _destinations
          .map((d) => NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)))
          .toList(),
    );

    return Scaffold(
      appBar: AppTopBar(title: _destinations[_index].label),
      body: Row(
        children: [
          rail,
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }
}
