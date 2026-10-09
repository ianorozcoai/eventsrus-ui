import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/models/business_type.dart';
import '../../marketplace/data/models/vendor_legal_document.dart';
import '../../support/presentation/support_tickets_screen.dart';
import '../data/models/legal_document_type.dart';
import '../data/models/philippine_provinces.dart';
import '../data/models/vendor_event_type.dart';
import '../data/models/vendor_settings.dart';
import '../data/vendor_legal_document_api.dart';
import '../data/vendor_settings_api.dart';
import 'widgets/image_upload_tile.dart';
import 'widgets/multi_select_field.dart';
import 'widgets/payment_methods_tab.dart';
import 'widgets/social_media_tab.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  bool _saving = false;
  // Keeps the full last-loaded settings (including fields this screen has
  // no form control for, e.g. storefrontOverview - kept read/write on the
  // model for real-DTO parity even though no UI edits it, see
  // VendorSettings' own doc comment) since _save() below must copyWith()
  // from this rather than build a bare VendorSettings(), or every save
  // from this screen would blank out those other fields.
  VendorSettings? _settings;
  List<VendorLegalDocument>? _legalDocuments;

  final _businessName = TextEditingController();
  final _description = TextEditingController();
  final _ownerName = TextEditingController();
  final _contactEmail = TextEditingController();
  final _phoneNumber = TextEditingController();
  Set<BusinessType> _businessTypes = {};

  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();

  // Picked-this-session replacements - null means "keep whatever's already
  // on file" (shown via _settings!.xUrl), only sent to the server if set.
  PlatformFile? _logo;
  PlatformFile? _idCard;
  PlatformFile? _selfie;
  PlatformFile? _cancellationPolicyFile;
  PlatformFile? _refundTermsFile;

  final _maxGuestCapacity = TextEditingController();
  final _maxCustomersPerDay = TextEditingController();
  final _basePrice = TextEditingController();
  final _leadTimeDays = TextEditingController();
  List<String> _operatingAreas = [];
  Set<VendorEventType> _cateredEventTypes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessName.dispose();
    _description.dispose();
    _ownerName.dispose();
    _contactEmail.dispose();
    _phoneNumber.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _state.dispose();
    _postalCode.dispose();
    _country.dispose();
    _maxGuestCapacity.dispose();
    _maxCustomersPerDay.dispose();
    _basePrice.dispose();
    _leadTimeDays.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        context.read<VendorSettingsApi>().getSettings(),
        context.read<VendorLegalDocumentApi>().list(),
      ]);
      if (!mounted) return;
      final settings = results[0] as VendorSettings;
      _settings = settings;
      _legalDocuments = results[1] as List<VendorLegalDocument>;
      _businessName.text = settings.businessName ?? '';
      _description.text = settings.description ?? '';
      _ownerName.text = settings.ownerName ?? '';
      _contactEmail.text = settings.contactEmail ?? '';
      _phoneNumber.text = settings.phoneNumber ?? '';
      _businessTypes = settings.businessTypes.toSet();
      _addressLine1.text = settings.addressLine1 ?? '';
      _addressLine2.text = settings.addressLine2 ?? '';
      _city.text = settings.city ?? '';
      _state.text = settings.state ?? '';
      _postalCode.text = settings.postalCode ?? '';
      _country.text = settings.country ?? 'Philippines';
      _maxGuestCapacity.text = settings.maxGuestCapacity?.toString() ?? '';
      _maxCustomersPerDay.text = settings.maxCustomersPerDay?.toString() ?? '';
      _basePrice.text = settings.basePrice?.toString() ?? '';
      _leadTimeDays.text = settings.leadTimeDays?.toString() ?? '';
      _operatingAreas = List.of(settings.operatingAreas);
      _cateredEventTypes = settings.cateredEventTypes.toSet();
      _logo = null;
      _idCard = null;
      _selfie = null;
      _cancellationPolicyFile = null;
      _refundTermsFile = null;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final current = _settings;
    if (current == null) return;

    setState(() => _saving = true);
    try {
      final updated = await context.read<VendorSettingsApi>().updateSettings(
            current.copyWith(
              businessName: _businessName.text.trim(),
              description: _description.text.trim(),
              ownerName: _ownerName.text.trim(),
              businessTypes: _businessTypes.toList(),
              contactEmail: _contactEmail.text.trim(),
              phoneNumber: _phoneNumber.text.trim(),
              addressLine1: _addressLine1.text.trim(),
              addressLine2: _addressLine2.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              postalCode: _postalCode.text.trim(),
              country: _country.text.trim(),
              maxGuestCapacity: int.tryParse(_maxGuestCapacity.text.trim()),
              maxCustomersPerDay: int.tryParse(_maxCustomersPerDay.text.trim()),
              basePrice: double.tryParse(_basePrice.text.trim()),
              leadTimeDays: int.tryParse(_leadTimeDays.text.trim()),
              operatingAreas: _operatingAreas,
              cateredEventTypes: _cateredEventTypes.toList(),
            ),
            logo: _logo,
            idCard: _idCard,
            selfie: _selfie,
            cancellationPolicyFile: _cancellationPolicyFile,
            refundTermsFile: _refundTermsFile,
          );
      if (!mounted) return;
      setState(() {
        _settings = updated;
        _logo = null;
        _idCard = null;
        _selfie = null;
        _cancellationPolicyFile = null;
        _refundTermsFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save settings')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyStorefrontUrl() async {
    final slug = _settings?.slug;
    if (slug == null) return;
    await Clipboard.setData(ClipboardData(text: '${AppConfig.webBaseUrl}/vendor/storefront/$slug'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storefront link copied')));
  }

  Future<void> _addLegalDocument() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddLegalDocumentDialog(),
    );
    if (added == true) await _load();
  }

  Future<void> _deleteLegalDocument(VendorLegalDocument document) async {
    final confirmed = await _confirmDialog(context, 'Remove this document permanently? This cannot be undone.');
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorLegalDocumentApi>().delete(document.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final settings = _settings;
    if (settings == null) {
      return const Center(child: Text('Could not load your account settings.'));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Account Settings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
                    ),
                    icon: const Icon(Icons.support_agent_outlined),
                    label: const Text('Support'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Submitting documents doesn't verify the account by itself -
              // an admin reviews them first (see settings.html's matching
              // alert).
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (settings.verified ? Colors.green : colorScheme.secondaryContainer).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(settings.verified ? Icons.verified_outlined : Icons.schedule_outlined,
                        color: settings.verified ? Colors.green : colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settings.verified
                            ? 'Verified supplier. Your storefront shows the Verified badge.'
                            : 'Verification pending. An EventsRUs admin reviews your submitted ID, selfie, and '
                                "business documents before your storefront shows the Verified badge - this "
                                "usually doesn't affect your ability to receive bookings in the meantime.",
                      ),
                    ),
                  ],
                ),
              ),
              if (settings.slug != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Public Storefront URL', style: Theme.of(context).textTheme.labelLarge),
                              Text(
                                '${AppConfig.webBaseUrl}/vendor/storefront/${settings.slug}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _copyStorefrontUrl,
                          icon: const Icon(Icons.copy_outlined),
                          tooltip: 'Copy',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '1. Business Info & Credentials'),
            Tab(text: '2. Service Scope & Metrics'),
            Tab(text: '3. Supplier Policies'),
            Tab(text: 'Payment Methods'),
            Tab(text: 'Social Media'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _tabPadding([
                TextField(controller: _businessName, decoration: const InputDecoration(labelText: 'Legal / Business Name')),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Business Description'),
                  maxLines: 2,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    "Shown right on your public storefront, under your business name.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _ownerName, decoration: const InputDecoration(labelText: 'Owner Name')),
                const SizedBox(height: 12),
                TextField(controller: _contactEmail, decoration: const InputDecoration(labelText: 'Contact Email')),
                const SizedBox(height: 12),
                TextField(controller: _phoneNumber, decoration: const InputDecoration(labelText: 'Support Phone')),
                const SizedBox(height: 20),
                Text(
                  'Also shown as your storefront\'s categories.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 8),
                MultiSelectField<BusinessType>(
                  label: 'Business Type(s)',
                  options: BusinessType.values,
                  selected: _businessTypes,
                  itemLabel: (type) => type.label,
                  onChanged: (selected) => setState(() => _businessTypes = selected),
                ),
                const SizedBox(height: 20),
                Text('Address', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _addressLine1, decoration: const InputDecoration(labelText: 'Address Line 1')),
                const SizedBox(height: 12),
                TextField(controller: _addressLine2, decoration: const InputDecoration(labelText: 'Address Line 2')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _city, decoration: const InputDecoration(labelText: 'City'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: _state, decoration: const InputDecoration(labelText: 'Province')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child:
                          TextField(controller: _postalCode, decoration: const InputDecoration(labelText: 'Postal Code')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Documents', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  "What you uploaded at onboarding. Replace any of these to update what's on file - the ID card and "
                  "selfie stay private and are only visible to EventsRUs admins.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 8),
                _CurrentFileLink(label: 'Current logo', url: settings.logoImageUrl),
                ImageUploadTile(label: 'Logo', file: _logo, onChanged: (file) => setState(() => _logo = file)),
                const SizedBox(height: 12),
                _CurrentFileLink(label: 'Current ID card', url: settings.idCardUrl),
                ImageUploadTile(label: 'ID card', file: _idCard, onChanged: (file) => setState(() => _idCard = file)),
                const SizedBox(height: 12),
                _CurrentFileLink(label: 'Current selfie', url: settings.selfieUrl),
                ImageUploadTile(label: 'Selfie', file: _selfie, onChanged: (file) => setState(() => _selfie = file)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Legal Documents',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: _addLegalDocument,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Document'),
                    ),
                  ],
                ),
                Text(
                  "DTI, SEC, Mayor's Permit, Barangay Clearance, BIR, etc.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 8),
                if ((_legalDocuments ?? const []).isEmpty)
                  Text('No legal documents uploaded yet.', style: Theme.of(context).textTheme.bodySmall)
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final doc in _legalDocuments!)
                        _LegalDocumentTile(document: doc, onDelete: () => _deleteLegalDocument(doc)),
                    ],
                  ),
              ]),
              _tabPadding([
                TextField(
                  controller: _maxGuestCapacity,
                  decoration: const InputDecoration(labelText: 'Maximum Guest Capacity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxCustomersPerDay,
                  decoration: const InputDecoration(labelText: 'Maximum Customers Per Day'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _basePrice,
                  decoration: const InputDecoration(labelText: 'Base Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _leadTimeDays,
                  decoration: const InputDecoration(labelText: 'Standard Lead Time (days)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                MultiSelectField<String>(
                  label: 'Operating Areas (Provinces)',
                  options: PhilippineProvinces.operatingAreaOptions,
                  selected: _operatingAreas.toSet(),
                  itemLabel: (area) => area,
                  onChanged: (selected) => setState(() => _operatingAreas = selected.toList()),
                ),
                const SizedBox(height: 20),
                MultiSelectField<VendorEventType>(
                  label: 'Event Types Catered To',
                  options: VendorEventType.values,
                  selected: _cateredEventTypes,
                  itemLabel: (type) => type.label,
                  onChanged: (selected) => setState(() => _cateredEventTypes = selected),
                ),
              ]),
              _tabPadding([
                Text(
                  'Upload these as PDF documents - planners can view them directly on your storefront. Only PDF '
                  'files are accepted.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 16),
                _PolicyPdfUpload(
                  label: 'Cancellation Policy',
                  currentUrl: settings.cancellationPolicyUrl,
                  file: _cancellationPolicyFile,
                  onChanged: (file) => setState(() => _cancellationPolicyFile = file),
                ),
                const SizedBox(height: 20),
                _PolicyPdfUpload(
                  label: 'Refund Terms',
                  currentUrl: settings.refundTermsUrl,
                  file: _refundTermsFile,
                  onChanged: (file) => setState(() => _refundTermsFile = file),
                ),
              ]),
              const PaymentMethodsTab(),
              const SocialMediaTab(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabPadding(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

Future<bool?> _confirmDialog(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirm')),
      ],
    ),
  );
}

/// "View current file" link shown above a replace-file picker - opens
/// in-app via the system browser (these can be PDFs, unlike the
/// gallery/package photos elsewhere in this app, so there's no single
/// viewer that handles both image and PDF cases the way eventsrus-web's
/// shared lightbox does).
class _CurrentFileLink extends StatelessWidget {
  final String label;
  final String? url;

  const _CurrentFileLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('No file uploaded yet.', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextButton.icon(
        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _PolicyPdfUpload extends StatelessWidget {
  final String label;
  final String? currentUrl;
  final PlatformFile? file;
  final ValueChanged<PlatformFile?> onChanged;

  const _PolicyPdfUpload({
    required this.label,
    required this.currentUrl,
    required this.file,
    required this.onChanged,
  });

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) onChanged(result.files.single);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        _CurrentFileLink(label: 'View current file', url: currentUrl),
        InkWell(
          onTap: _pick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              border: Border.all(color: file != null ? colorScheme.primary : colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined, color: colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file != null ? file!.name : 'Tap to upload a PDF',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(file != null ? Icons.check_circle : Icons.upload_outlined,
                    color: file != null ? colorScheme.primary : colorScheme.outline),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'PDF only. Uploading a new file replaces the current one.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

class _LegalDocumentTile extends StatelessWidget {
  final VendorLegalDocument document;
  final VoidCallback onDelete;

  const _LegalDocumentTile({required this.document, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  document.label ?? document.documentType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(onTap: onDelete, child: const Icon(Icons.close, size: 18)),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(document.url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('View file'),
          ),
        ],
      ),
    );
  }
}

class _AddLegalDocumentDialog extends StatefulWidget {
  const _AddLegalDocumentDialog();

  @override
  State<_AddLegalDocumentDialog> createState() => _AddLegalDocumentDialogState();
}

class _AddLegalDocumentDialogState extends State<_AddLegalDocumentDialog> {
  LegalDocumentType _type = LegalDocumentType.dtiPermit;
  final _label = TextEditingController();
  PlatformFile? _file;
  bool _submitting = false;
  String? _fileError;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.single;
        _fileError = null;
      });
    }
  }

  Future<void> _submit() async {
    final file = _file;
    if (file == null) {
      setState(() => _fileError = 'Please choose a document file.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final label = _label.text.trim();
      await context.read<VendorLegalDocumentApi>().create(
            documentType: _type,
            label: label.isEmpty ? null : label,
            file: file,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Legal Document'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<LegalDocumentType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: LegalDocumentType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label (optional)', hintText: 'e.g., Fire Safety Certificate'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_file != null ? _file!.name : 'Choose file'),
            ),
            if (_fileError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_fileError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Image or PDF. Uploaded right away.', style: TextStyle(fontSize: 12)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add Document'),
        ),
      ],
    );
  }
}
