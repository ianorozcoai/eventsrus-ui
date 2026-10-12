import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/ui/error_display.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/data/models/business_type.dart';
import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import 'vendor_profile_screen.dart';

/// The planner's checklist for one event, its own tab (separate from
/// Overview's 3-step gather-info/select-categories/browse-suppliers
/// wizard). One group per category - a category's own "Book a X vendor"
/// item and any "Follow up with Y" bookmark items for that category land
/// in the same group (see backend's EventService#setVendorBookmark
/// category-context resolution); planner-typed custom items (no category)
/// sit in their own "Other" group.
class EventChecklistTab extends StatefulWidget {
  final PlannerEvent event;

  const EventChecklistTab({super.key, required this.event});

  @override
  State<EventChecklistTab> createState() => _EventChecklistTabState();
}

class _EventChecklistTabState extends State<EventChecklistTab> {
  late List<EventChecklistItem> _checklist;
  int? _busyChecklistItemId;
  bool _addingItem = false;

  @override
  void initState() {
    super.initState();
    _checklist = List.of(widget.event.checklist);
  }

  @override
  void didUpdateWidget(EventChecklistTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checklist = List.of(widget.event.checklist);
  }

  Map<String, List<EventChecklistItem>> _checklistByCategory() {
    final byCategory = <String, List<EventChecklistItem>>{};
    for (final item in _checklist) {
      if (item.vendorType != null) {
        byCategory.putIfAbsent(item.vendorType!, () => []).add(item);
      }
    }
    final ordered = <String, List<EventChecklistItem>>{};
    for (final type in byCategory.keys.toList()
      ..sort((a, b) => BusinessTypeApi.fromApi(a).label.compareTo(BusinessTypeApi.fromApi(b).label))) {
      ordered[type] = byCategory[type]!;
    }
    return ordered;
  }

  List<EventChecklistItem> get _uncategorizedChecklistItems =>
      _checklist.where((item) => item.vendorType == null).toList();

  // Bookmarked suppliers in this category, not the total match count (that
  // moved to Search Result's own rows) - a bookmark-origin item is one with
  // a vendorSlug (see the "View Storefront" button on each tile below).
  int _bookmarkedCountFor(String vendorType) =>
      _checklist.where((item) => item.vendorType == vendorType && item.vendorSlug != null).length;

  Future<void> _updateStatus(EventChecklistItem item, ChecklistItemStatus newStatus, {String? confirmMessage}) async {
    if (confirmMessage != null) {
      final confirmed = await showConfirmDialog(
        context,
        message: confirmMessage,
        confirmLabel: newStatus == ChecklistItemStatus.done ? 'Done' : 'Remove',
      );
      if (confirmed != true || !mounted) return;
    }
    final eventApi = context.read<EventApi>();
    setState(() => _busyChecklistItemId = item.id);
    try {
      final updated = await eventApi.updateChecklistStatus(widget.event.id, item.id, newStatus);
      if (!mounted) return;
      setState(() {
        final index = _checklist.indexWhere((e) => e.id == item.id);
        if (index != -1) _checklist[index] = updated;
      });
    } catch (e, st) {
      AppLogger.error('EventChecklistTab', 'Failed to update checklist item', error: e, stackTrace: st);
      if (!mounted) return;
      showFriendlyError(context, message: 'Could not update checklist item');
    } finally {
      if (mounted) setState(() => _busyChecklistItemId = null);
    }
  }

  Future<void> _addChecklistItem() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add checklist item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. "Book the venue"'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;

    setState(() => _addingItem = true);
    try {
      final item = await context.read<EventApi>().addChecklistItem(widget.event.id, label);
      if (!mounted) return;
      setState(() => _checklist = [..._checklist, item]);
    } catch (e, st) {
      AppLogger.error('EventChecklistTab', 'Failed to add checklist item', error: e, stackTrace: st);
      if (!mounted) return;
      showFriendlyError(context, message: 'Could not add checklist item');
    } finally {
      if (mounted) setState(() => _addingItem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('Checklist', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            _addingItem
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add checklist item',
                    onPressed: _addChecklistItem,
                  ),
          ],
        ),
        if (_checklist.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nothing on the checklist yet - select a category in Search Result to add it here.'),
          )
        else ...[
          for (final entry in _checklistByCategory().entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Row(
                children: [
                  Text(
                    BusinessTypeApi.fromApi(entry.key).label,
                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_bookmarkedCountFor(entry.key) > 0) ...[
                    const SizedBox(width: 6),
                    Chip(
                      label: Text('${_bookmarkedCountFor(entry.key)} bookmarked'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
              ),
            ),
            for (final item in entry.value) _checklistItemTile(item),
          ],
          if (_uncategorizedChecklistItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text('Other', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            for (final item in _uncategorizedChecklistItems) _checklistItemTile(item),
          ],
        ],
      ],
    );
  }

  Widget _checklistItemTile(EventChecklistItem item) {
    final busy = _busyChecklistItemId == item.id;
    Color? labelColor;
    TextDecoration? decoration;
    Widget? statusIcon;
    switch (item.status) {
      case ChecklistItemStatus.done:
        labelColor = Colors.green;
        statusIcon = const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case ChecklistItemStatus.dismissed:
        labelColor = Colors.red;
        decoration = TextDecoration.lineThrough;
      case ChecklistItemStatus.todo:
        break;
    }

    return Padding(
      key: ValueKey('checklist-${item.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (statusIcon != null) ...[statusIcon, const SizedBox(width: 6)],
              Expanded(child: Text(item.label, style: TextStyle(color: labelColor, decoration: decoration))),
            ],
          ),
          const SizedBox(height: 4),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ..._checklistActionButtons(item),
                // A category-origin item has its own Browse pop-up on
                // Search Result instead; a bookmark-origin item (a
                // specific vendor) links straight to their storefront.
                if (item.vendorSlug != null)
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VendorProfileScreen(slug: item.vendorSlug!, eventId: widget.event.id),
                      ),
                    ),
                    child: const Text('View Storefront'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _checklistActionButtons(EventChecklistItem item) {
    switch (item.status) {
      case ChecklistItemStatus.todo:
        return [
          OutlinedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Done'),
            onPressed: () =>
                _updateStatus(item, ChecklistItemStatus.done, confirmMessage: 'Mark this item as done?'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Remove'),
            onPressed: () => _updateStatus(
              item,
              ChecklistItemStatus.dismissed,
              confirmMessage: 'No longer interested in this? It will be crossed out but stays on your checklist.',
            ),
          ),
        ];
      case ChecklistItemStatus.done:
        return [
          // No confirmation - a deliberate low-friction "oops" escape hatch.
          // OutlinedButton (not TextButton) so this reads as a tappable
          // button, not plain text, matching Done/Remove above.
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
            label: const Text('Undo', style: TextStyle(color: Colors.green)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
            onPressed: () => _updateStatus(item, ChecklistItemStatus.todo),
          ),
        ];
      case ChecklistItemStatus.dismissed:
        return [
          OutlinedButton.icon(
            icon: const Icon(Icons.undo, size: 16, color: Colors.grey),
            label: const Text('Undo', style: TextStyle(color: Colors.grey)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
            onPressed: () => _updateStatus(item, ChecklistItemStatus.todo),
          ),
        ];
    }
  }
}
