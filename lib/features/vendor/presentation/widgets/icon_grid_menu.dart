import 'package:flutter/material.dart';

/// One destination in an [IconGridMenu]/[GroupedIconGridMenu] - a tinted
/// rounded-square icon tile with a label underneath, the same pattern
/// banking apps use for their "More" hub (tap the tile, push the real
/// screen).
class IconGridItem {
  final IconData icon;
  final String label;
  final Color tint;
  final WidgetBuilder builder;

  // Most of these destination screens were written as pure body content
  // for the old shared-shell Scaffold (AppTopBar + bottomNavigationBar in
  // vendor_shell.dart's wide layout) - they have no Scaffold/AppBar of
  // their own, so pushing item.builder directly leaves no back button and
  // no header at all. Default false wraps item.builder in a generic
  // Scaffold+AppBar(title: label) at push time so every tile gets a back
  // button for free; set true only for the few screens that already build
  // their own proper Scaffold+AppBar (e.g. SupportTicketsScreen,
  // BillingHistoryScreen), to avoid stacking two app bars.
  final bool hasOwnAppBar;

  const IconGridItem({
    required this.icon,
    required this.label,
    required this.tint,
    required this.builder,
    this.hasOwnAppBar = false,
  });
}

/// Cycling pastel palette so a flat list of destinations reads as a set of
/// distinct shortcuts rather than one monotone block, without having to hand
/// a color to every call site.
const List<Color> iconGridPalette = [
  Color(0xFF0C83FF),
  Color(0xFF8E70C1),
  Color(0xFF26A69A),
  Color(0xFFF58646),
  Color(0xFF059669),
  Color(0xFFF35C86),
  Color(0xFFFFB300),
];

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 4,
  mainAxisSpacing: 16,
  crossAxisSpacing: 8,
  childAspectRatio: 0.78,
);

class _IconGridTile extends StatelessWidget {
  final IconGridItem item;

  const _IconGridTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: item.hasOwnAppBar
              ? item.builder
              : (ctx) => Scaffold(appBar: AppBar(title: Text(item.label)), body: item.builder(ctx)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.tint),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Grid of tinted icon tiles - the phone-width "hub" page pattern used by
/// VendorCustomersHubScreen to fan out into several real screens from one
/// bottom-nav destination. For a hub with several distinct groups (e.g.
/// VendorMoreScreen), use [GroupedIconGridMenu] instead.
class IconGridMenu extends StatelessWidget {
  final List<IconGridItem> items;

  /// Section label above the grid - e.g. "Customer Management" - so it's
  /// clear which group of modules this hub tab fanned out into, not just a
  /// bare set of icons.
  final String? title;

  const IconGridMenu({super.key, required this.items, this.title});

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: _gridDelegate,
      itemBuilder: (context, i) => _IconGridTile(item: items[i]),
    );

    final title = this.title;
    if (title == null) return grid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: grid),
      ],
    );
  }
}

/// One labeled group of tiles within a [GroupedIconGridMenu] - e.g. "Billing
/// and Subscription" containing just the Billing tile.
class IconGridSection {
  final String title;
  final List<IconGridItem> items;

  const IconGridSection({required this.title, required this.items});
}

/// Several labeled tile groups stacked vertically, each with its own
/// section heading - the pattern reference banking apps use for a "More"
/// page with more than one kind of destination on it (Invest / Services /
/// Transactions / ... each as their own row), as opposed to [IconGridMenu]'s
/// single flat grid.
class GroupedIconGridMenu extends StatelessWidget {
  final List<IconGridSection> sections;

  const GroupedIconGridMenu({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.items.length,
            gridDelegate: _gridDelegate,
            itemBuilder: (context, i) => _IconGridTile(item: section.items[i]),
          ),
        ],
      ],
    );
  }
}
