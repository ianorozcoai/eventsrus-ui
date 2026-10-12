import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/ui/error_display.dart';
import '../data/event_api.dart';
import '../data/models/event_recommendations.dart';
import '../data/models/philippine_provinces.dart';
import '../data/models/planner_event_type.dart';
import 'planner_event_shell.dart';

/// Pre-creation 2-step wizard: STEP 1 collects event details (unchanged
/// fields, no network call), STEP 2 lets the planner pick supplier
/// categories - purely client-side state, no backend calls per checkbox.
/// The event itself is only created when STEP 2's "Next" is pressed, which
/// then also fires the category selections - mirrors eventsrus-web's
/// create-event wizard (see PlannerController#createEventAjax).
class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  PlannerEventType _eventType = PlannerEventType.wedding;
  DateTime? _eventDate;
  String? _location;
  final _budgetController = TextEditingController();
  final _guestCountController = TextEditingController();

  String? _dateError;
  int _step = 1;

  bool _loadingRecommendations = false;
  EventRecommendations? _recommendations;
  final Map<String, bool> _categorySelected = {};
  final Map<String, double?> _categoryBudget = {};
  bool _showOptional = false;

  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _goToStep2() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final dateValid = _eventDate != null;
    setState(() => _dateError = dateValid ? null : 'Required');
    if (!formValid || !dateValid) return;

    setState(() => _step = 2);
    if (_recommendations == null) await _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      final recommendations = await context.read<EventApi>().getRecommendations(_eventType);
      if (!mounted) return;
      setState(() {
        _recommendations = recommendations;
        for (final cat in [...recommendations.essential, ...recommendations.optional]) {
          _categorySelected.putIfAbsent(cat.type, () => false);
        }
      });
    } catch (e, st) {
      AppLogger.error('EventCreateScreen', 'Failed to load supplier recommendations', error: e, stackTrace: st);
      if (!mounted) return;
      showFriendlyError(context, message: 'Could not load supplier categories');
      setState(() => _step = 1);
    } finally {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  Future<void> _createEventAndSelections() async {
    final eventApi = context.read<EventApi>();
    setState(() => _creating = true);
    try {
      final created = await eventApi.createEvent(
            name: _nameController.text.trim(),
            eventType: _eventType,
            eventDate: _eventDate!,
            location: _location!,
            budget: double.tryParse(_budgetController.text.trim()),
            guestCount: int.tryParse(_guestCountController.text.trim()),
          );
      // The event now exists - from here on, always land the planner on it
      // rather than leaving them stuck on this screen (retrying "Next"
      // would call createEvent again and produce a duplicate event). A
      // category call failing is a best-effort miss they can redo later
      // from Search Result, not a reason to abandon the event that's
      // already saved. Fired concurrently (not one at a time) and their
      // individual responses discarded - PlannerEventShell does its own
      // getEvent() on mount, which is the real source of truth, so there's
      // no need to merge responses from requests that may resolve out of
      // order.
      final selectedTypes = _categorySelected.entries.where((e) => e.value).map((e) => e.key);
      await Future.wait(selectedTypes.map(
        (type) => eventApi
            .setSupplierTypeSelection(created.id, type, selected: true, budget: _categoryBudget[type])
            .catchError((_) => created),
      ));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PlannerEventShell(eventId: created.id)),
      );
    } catch (e, st) {
      AppLogger.error('EventCreateScreen', 'Failed to create event', error: e, stackTrace: st);
      if (!mounted) return;
      showFriendlyError(context, message: 'Could not create event');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_step == 1 ? 'STEP 1: Tell me about your event' : 'STEP 2: Select suppliers')),
      // top: false - the AppBar already clears the top inset; this is only
      // for the bottom, which nothing else here accounts for (no
      // bottomNavigationBar on this screen) and which otherwise lets the
      // Back/Next row run under Android's edge-to-edge gesture/nav bar.
      body: SafeArea(
        top: false,
        // Align (not Center) - Center would also center the form vertically,
        // leaving a large empty gap above it since the form is shorter than
        // the screen; topCenter keeps the horizontal max-width centering
        // without pushing the content down.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 1 ? _buildStep1() : _buildStep2(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell us about your event',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Event Name'),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PlannerEventType>(
            initialValue: _eventType,
            decoration: const InputDecoration(labelText: 'Type of Event'),
            items: PlannerEventType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
            onChanged: (v) => setState(() => _eventType = v ?? _eventType),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date',
              errorText: _dateError,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  _eventDate == null ? 'Select a date' : '${_eventDate!.month}/${_eventDate!.day}/${_eventDate!.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              helperText: 'A province so we can recommend real suppliers near you',
            ),
            items: PhilippineProvinces.all.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _location = v),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(labelText: 'Budget (optional)', prefixText: '₱'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _guestCountController,
                  decoration: const InputDecoration(labelText: 'Guest Count (optional)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          // Description field hidden for now while we validate the
          // supplier-matching flow on its own - stays optional on the
          // backend, just not collected here right now.
          const SizedBox(height: 24),
          FilledButton(onPressed: _goToStep2, child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final recommendations = _recommendations;
    if (_loadingRecommendations || recommendations == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasSelection = _categorySelected.values.any((v) => v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select the suppliers you\'re interested in',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...recommendations.essential.map(_categoryTile),
        if (recommendations.optional.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showOptional = !_showOptional),
            child: Text(_showOptional
                ? 'Hide other categories'
                : 'Show ${recommendations.optional.length} other categories'),
          ),
          if (_showOptional) ...recommendations.optional.map(_categoryTile),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: _creating ? null : () => setState(() => _step = 1),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: (!hasSelection || _creating) ? null : _createEventAndSelections,
                child: _creating
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Processing data…'),
                        ],
                      )
                    : const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryTile(RecommendationCategory category) {
    final selected = _categorySelected[category.type] ?? false;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(category.label),
            value: selected,
            onChanged: (v) => setState(() => _categorySelected[category.type] = v ?? false),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Budget for this category (optional)', prefixText: '₱'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _categoryBudget[category.type] = double.tryParse(value.trim()),
              ),
            ),
        ],
      ),
    );
  }
}
