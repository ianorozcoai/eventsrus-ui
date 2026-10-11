import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/data/models/business_type.dart';
import '../../marketplace/data/models/vendor_search_result.dart';
import '../../marketplace/data/vendor_directory_api.dart';
import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import 'vendor_profile_screen.dart';

/// One business-type group for Search Result - every [vendors] row shares
/// the same [selected]/[budget]/[essential], read off the first (see
/// backend SuggestedVendorResponse's javadoc). [vendors] only ever holds
/// real matches (vendorProfileId != null) - a category with zero matches
/// still gets a group (so it can still be removed/browsed), just with an
/// empty list.
class _SupplierCategoryGroup {
  final String vendorType;
  final bool selected;
  final double? budget;
  final bool essential;
  final List<SuggestedVendor> vendors;

  const _SupplierCategoryGroup({
    required this.vendorType,
    required this.selected,
    required this.budget,
    required this.essential,
    required this.vendors,
  });
}

/// The "Search Result" tab inside [PlannerEventShell] (formerly "Overview")
/// - one row per category the planner selected during the pre-creation
/// wizard (see event_create_screen.dart), each with a "Browse" popup of
/// that category's matched suppliers and a remove action. Category
/// selection is no longer a step inside this tab - it only happens at
/// creation time, or afterward via the "Add category" pop-up here.
class EventSearchResultTab extends StatefulWidget {
  final PlannerEvent event;
  final VoidCallback onGoToChat;
  final ValueChanged<PlannerEvent> onEventUpdated;

  const EventSearchResultTab({
    super.key,
    required this.event,
    required this.onGoToChat,
    required this.onEventUpdated,
  });

  @override
  State<EventSearchResultTab> createState() => _EventSearchResultTabState();
}

class _EventSearchResultTabState extends State<EventSearchResultTab> {
  final Set<String> _busyCategoryTypes = {};

  List<_SupplierCategoryGroup> _supplierCategoryGroups(PlannerEvent event) {
    final byType = <String, List<SuggestedVendor>>{};
    for (final s in event.suggestions) {
      byType.putIfAbsent(s.vendorType, () => []);
      if (s.isRealVendor) byType[s.vendorType]!.add(s);
    }
    return event.suggestions
        .map((s) => s.vendorType)
        .toSet()
        .map((type) {
          final rows = byType[type]!;
          final first = event.suggestions.firstWhere((s) => s.vendorType == type);
          return _SupplierCategoryGroup(
            vendorType: type,
            selected: first.categorySelected,
            budget: first.categoryBudget,
            essential: first.essential,
            vendors: rows,
          );
        })
        .toList();
  }

  String _categoryLabel(String vendorType) {
    try {
      return BusinessTypeApi.fromApi(vendorType).label;
    } catch (_) {
      return vendorType;
    }
  }

  Future<void> _removeCategory(_SupplierCategoryGroup group) async {
    final label = _categoryLabel(group.vendorType);
    final confirmed = await showConfirmDialog(
      context,
      message: 'Remove $label from your Search Result? This also deletes every checklist '
          "item under this category - this can't be undone.",
      confirmLabel: 'Remove',
    );
    if (confirmed != true || !mounted) return;
    final eventApi = context.read<EventApi>();
    setState(() => _busyCategoryTypes.add(group.vendorType));
    try {
      final updated = await eventApi.removeSupplierType(widget.event.id, group.vendorType);
      if (!mounted) return;
      // Refreshes this tab AND the Checklist tab - PlannerEventShell passes
      // the same event to both via one IndexedStack, and EventChecklistTab
      // already re-derives its local list from widget.event.checklist.
      widget.onEventUpdated(updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not remove category')));
    } finally {
      if (mounted) setState(() => _busyCategoryTypes.remove(group.vendorType));
    }
  }

  void _openAddCategoryScreen(List<_SupplierCategoryGroup> initial) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AddCategoryScreen(
          initial: initial,
          eventId: widget.event.id,
          categoryLabelOf: _categoryLabel,
          onEventUpdated: widget.onEventUpdated,
        ),
      ),
    );
  }

  void _openBrowseScreen(_SupplierCategoryGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CategoryBrowseScreen(
          categoryLabel: _categoryLabel(group.vendorType),
          vendorType: group.vendorType,
          vendors: group.vendors,
          eventId: widget.event.id,
          categoryLabelOf: _categoryLabel,
        ),
      ),
    );
  }

  void _openNameSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Search for a supplier')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: _NameSearchPopupContent(eventId: widget.event.id),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = _supplierCategoryGroups(widget.event);
    final selected = groups.where((g) => g.selected).toList();
    final unselected = groups.where((g) => !g.selected).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Search Result', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
            TextButton(onPressed: widget.onGoToChat, child: const Text('Open Chat')),
          ],
        ),
        const SizedBox(height: 12),
        // Stacked, not side-by-side - "Do you have a supplier in mind?"
        // wraps to two lines while "Add category" stays on one, so a Row
        // of two Expanded buttons made them different heights. Stacking
        // keeps both the same width and the same height as each other.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Do you have a supplier in mind?'),
            onPressed: _openNameSearchScreen,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
            onPressed: unselected.isEmpty ? null : () => _openAddCategoryScreen(unselected),
          ),
        ),
        const SizedBox(height: 16),
        if (selected.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No categories selected yet - tap "Add category" to get started.'),
          )
        else
          for (final group in selected) _categoryRow(group),
      ],
    );
  }

  Widget _categoryRow(_SupplierCategoryGroup group) {
    final busy = _busyCategoryTypes.contains(group.vendorType);
    return Card(
      child: ListTile(
        title: Text(_categoryLabel(group.vendorType)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text('${group.vendors.length} match${group.vendors.length == 1 ? '' : 'es'}'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            TextButton(onPressed: () => _openBrowseScreen(group), child: const Text('Browse')),
            busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove category',
                    onPressed: () => _removeCategory(group),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Full screen (not a pop-up) listing one category's matched suppliers -
/// pushed with a normal back arrow, matching every other screen in this
/// app (VendorProfileScreen, etc.). A fixed-width dialog made each vendor
/// row's title column too narrow once a leading avatar and a trailing
/// "View Storefront" button were both present, wrapping business names
/// character-by-character - a full screen gives the title column the
/// whole screen width instead.
class _CategoryBrowseScreen extends StatelessWidget {
  final String categoryLabel;
  final String vendorType;
  final List<SuggestedVendor> vendors;
  final int eventId;
  final String Function(String) categoryLabelOf;

  const _CategoryBrowseScreen({
    required this.categoryLabel,
    required this.vendorType,
    required this.vendors,
    required this.eventId,
    required this.categoryLabelOf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryLabel)),
      body: vendors.isEmpty
          ? const Center(child: Text('No matching suppliers in this area yet - check back later.'))
          : ListView.builder(
              itemCount: vendors.length,
              itemBuilder: (_, i) {
                final vendor = vendors[i];
                return ListTile(
                  leading: vendor.logoImageUrl != null
                      ? CircleAvatar(backgroundImage: NetworkImage(vendor.logoImageUrl!))
                      : CircleAvatar(
                          child: Text((vendor.businessName?.isNotEmpty ?? false)
                              ? vendor.businessName![0].toUpperCase()
                              : '?'),
                        ),
                  // No business-type subtitle here - every row in this
                  // screen is already scoped to one category (the AppBar
                  // title), so repeating it per row is redundant (unlike
                  // the cross-category name search below, which still
                  // shows it).
                  title: Text(vendor.businessName ?? vendor.vendorType),
                  trailing: vendor.slug == null
                      ? null
                      : OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VendorProfileScreen(
                                slug: vendor.slug!,
                                eventId: eventId,
                                categoryContext: vendorType,
                              ),
                            ),
                          ),
                          child: const Text('View Storefront'),
                        ),
                );
              },
            ),
    );
  }
}

/// Full screen (not a pop-up) listing categories not yet selected for this
/// event - pushed with a normal back arrow, same reasoning as
/// _CategoryBrowseScreen above. Stateful (unlike that screen) because
/// adding a category removes its own row from this list without closing
/// the screen, so the planner can add several in a row.
class _AddCategoryScreen extends StatefulWidget {
  final List<_SupplierCategoryGroup> initial;
  final int eventId;
  final String Function(String) categoryLabelOf;
  final ValueChanged<PlannerEvent> onEventUpdated;

  const _AddCategoryScreen({
    required this.initial,
    required this.eventId,
    required this.categoryLabelOf,
    required this.onEventUpdated,
  });

  @override
  State<_AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<_AddCategoryScreen> {
  late List<_SupplierCategoryGroup> _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = List.of(widget.initial);
  }

  Future<void> _add(int index) async {
    final group = _remaining[index];
    final eventApi = context.read<EventApi>();
    try {
      final updated = await eventApi.setSupplierTypeSelection(widget.eventId, group.vendorType, selected: true);
      if (!mounted) return;
      widget.onEventUpdated(updated);
      setState(() => _remaining.removeAt(index));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add category')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a category')),
      body: _remaining.isEmpty
          ? const Center(child: Text('No more categories to add.'))
          : ListView.builder(
              itemCount: _remaining.length,
              itemBuilder: (_, i) {
                final group = _remaining[i];
                return ListTile(
                  title: Text(widget.categoryLabelOf(group.vendorType)),
                  // OutlinedButton, not FilledButton - matches every other
                  // per-row action in this app (Browse's "View Storefront",
                  // the checklist's Done/Remove), instead of standing out
                  // as the only solid-filled one.
                  trailing: OutlinedButton(
                    onPressed: () => _add(i),
                    child: const Text('Add'),
                  ),
                );
              },
            ),
    );
  }
}

/// Live-search content for the "Do you have a supplier in mind?" pop-up -
/// debounced, fires once the query reaches 3+ characters. Separate widget
/// (not a method) since it owns its own text controller/debounce timer.
class _NameSearchPopupContent extends StatefulWidget {
  final int eventId;

  const _NameSearchPopupContent({required this.eventId});

  @override
  State<_NameSearchPopupContent> createState() => _NameSearchPopupContentState();
}

class _NameSearchPopupContentState extends State<_NameSearchPopupContent> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<VendorSearchResult>? _results;
  bool _loading = false;

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final vendorDirectoryApi = context.read<VendorDirectoryApi>();
    setState(() => _loading = true);
    try {
      final results = await vendorDirectoryApi.search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      // Non-fatal - just leave the previous results (or hint) in place.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _businessTypeLabel(String raw) {
    try {
      return BusinessTypeApi.fromApi(raw).label;
    } catch (_) {
      return raw;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search by business name', prefixIcon: Icon(Icons.search)),
          onChanged: _onChanged,
        ),
        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: results == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Type at least 3 characters to search.')),
                )
              : results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No suppliers found.')),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final vendor = results[i];
                        return ListTile(
                          leading: vendor.logoImageUrl != null
                              ? CircleAvatar(backgroundImage: NetworkImage(vendor.logoImageUrl!))
                              : CircleAvatar(
                                  child: Text(
                                    vendor.businessName.isNotEmpty ? vendor.businessName[0].toUpperCase() : '?',
                                  ),
                                ),
                          title: Text(vendor.businessName),
                          subtitle: vendor.businessTypes.isEmpty
                              ? null
                              : Text(vendor.businessTypes.map(_businessTypeLabel).join(', ')),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VendorProfileScreen(slug: vendor.slug, eventId: widget.eventId),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
