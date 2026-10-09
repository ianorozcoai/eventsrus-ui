import 'package:flutter/material.dart';

import '../../marketplace/presentation/conversations_screen.dart';
import 'vendor_bookings_screen.dart';
import 'vendor_calendar_screen.dart';
import 'vendor_leads_screen.dart';
import 'vendor_quotations_screen.dart';
import 'widgets/icon_grid_menu.dart';

/// "Customers" bottom-nav destination - fans out into Calendar plus the same
/// Leads/Messages/Quotations/Bookings group as eventsrus-web's "Customer
/// Management" sidebar section, as a grid of shortcut tiles rather than a
/// list (matches the grid-hub pattern used by VendorMoreScreen).
class VendorCustomersHubScreen extends StatelessWidget {
  const VendorCustomersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IconGridMenu(
      title: 'Customer Management',
      items: [
        IconGridItem(
          icon: Icons.calendar_month_outlined,
          label: 'Calendar',
          tint: iconGridPalette[0],
          builder: (_) => const VendorCalendarScreen(),
        ),
        IconGridItem(
          icon: Icons.person_search_outlined,
          label: 'Leads',
          tint: iconGridPalette[1],
          builder: (_) => const VendorLeadsScreen(),
        ),
        IconGridItem(
          icon: Icons.chat_bubble_outline,
          label: 'Messages',
          tint: iconGridPalette[2],
          builder: (_) => const ConversationsScreen(),
        ),
        IconGridItem(
          icon: Icons.request_quote_outlined,
          label: 'Quotations',
          tint: iconGridPalette[3],
          builder: (_) => const VendorQuotationsScreen(),
        ),
        IconGridItem(
          icon: Icons.event_available_outlined,
          label: 'Bookings',
          tint: iconGridPalette[4],
          builder: (_) => const VendorBookingsScreen(),
        ),
      ],
    );
  }
}
