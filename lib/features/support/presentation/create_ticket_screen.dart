import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/ticket_category.dart';
import '../data/support_ticket_api.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  TicketCategory _category = TicketCategory.other;
  PlatformFile? _attachment;
  bool _submitting = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _attachment = result.files.first);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await context.read<SupportTicketApi>().createTicket(
            subject: _subject.text.trim(),
            category: _category,
            message: _message.text.trim(),
            attachment: _attachment,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Support Ticket')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TicketCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: TicketCategory.values
                    .map((category) => DropdownMenuItem(value: category, child: Text(category.label)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value ?? TicketCategory.other),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                decoration: const InputDecoration(
                  labelText: 'What\'s going on?',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.attach_file),
                label: Text(_attachment == null ? 'Attach a screenshot (optional)' : _attachment!.name),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
