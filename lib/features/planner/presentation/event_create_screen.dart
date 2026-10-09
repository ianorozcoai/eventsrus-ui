import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/event_api.dart';
import '../data/models/planner_event.dart';
import '../data/models/planner_event_type.dart';
import 'planner_event_shell.dart';

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  PlannerEventType _eventType = PlannerEventType.wedding;
  DateTime? _eventDate;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _submitting = false;
  PlannerEvent? _created;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final event = await context.read<EventApi>().createEvent(
            eventType: _eventType,
            eventDate: _eventDate,
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _created = event);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate suggestions')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveEvent() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Name your event'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "e.g. \"Ian's Birthday\""),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || _created == null) return;

    try {
      final saved = await context.read<EventApi>().saveEvent(_created!.id, name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PlannerEventShell(eventId: saved.id)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save event')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan a New Event')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: created == null ? _buildForm() : _buildSuggestions(created),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tell us about your event',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<PlannerEventType>(
          initialValue: _eventType,
          decoration: const InputDecoration(labelText: 'Type of Event'),
          items: PlannerEventType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) => setState(() => _eventType = v ?? _eventType),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_eventDate == null ? 'Select a date' : '${_eventDate!.month}/${_eventDate!.day}/${_eventDate!.year}'),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location (optional)',
            helperText: 'Give a city so we can recommend real vendors near you',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Tell us what you have in mind'),
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Get Suggestions'),
        ),
      ],
    );
  }

  Widget _buildSuggestions(PlannerEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Here\'s our idea', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(event.aiIdeaText ?? ''),
        if (event.location == null || event.location!.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "You didn't give us a location, so these are general vendor categories. "
              'Add a location next time to see real vendors near you.',
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Suggested Vendors', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...event.suggestions.map(
          (s) => Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(s.isRealVendor ? (s.businessName ?? s.vendorType) : s.vendorType),
              subtitle: Text(s.isRealVendor ? (s.city ?? '') : 'Category suggestion'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _saveEvent, child: const Text('Save This Event')),
      ],
    );
  }
}
