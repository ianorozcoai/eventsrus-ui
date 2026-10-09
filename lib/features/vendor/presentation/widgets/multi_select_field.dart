import 'package:flutter/material.dart';

/// Mobile-native counterpart to eventsrus-web's bootstrap_multiselect.js
/// dropdowns (filterable multi-select <select>s) - too many options to
/// read as a flat grid of toggle chips (e.g. BusinessType's 30 values), so
/// this is a tappable field that opens a searchable checklist sheet
/// instead, same searchable-multi-select UX in a mobile-appropriate shape.
class MultiSelectField<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final Set<T> selected;
  final String Function(T) itemLabel;
  final ValueChanged<Set<T>> onChanged;

  const MultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.itemLabel,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<Set<T>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MultiSelectSheet<T>(
        label: label,
        options: options,
        initialSelected: selected,
        itemLabel: itemLabel,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              selected.isEmpty ? 'None selected' : '${selected.length} selected',
              style: TextStyle(color: selected.isEmpty ? colorScheme.outline : null),
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in selected)
                Chip(
                  label: Text(itemLabel(item)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  final String label;
  final List<T> options;
  final Set<T> initialSelected;
  final String Function(T) itemLabel;

  const _MultiSelectSheet({
    required this.label,
    required this.options,
    required this.initialSelected,
    required this.itemLabel,
  });

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late Set<T> _selected;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.initialSelected);
    _search.addListener(() => setState(() => _query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options.where((o) => widget.itemLabel(o).toLowerCase().contains(_query)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search...',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return CheckboxListTile(
                    value: _selected.contains(item),
                    title: Text(widget.itemLabel(item)),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(item);
                      } else {
                        _selected.remove(item);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
