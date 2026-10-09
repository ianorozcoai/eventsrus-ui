import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/models/business_type.dart';
import '../../auth/state/auth_controller.dart';
import '../data/models/legal_document_type.dart';
import '../data/models/legal_document_upload.dart';
import '../data/models/vendor_onboarding_request.dart';
import '../data/vendor_api.dart';
import 'widgets/image_upload_tile.dart';

/// One business-registration document row in the onboarding form - the
/// vendor can add any number of these (see _VendorOnboardingScreenState).
class _LegalDocumentRow {
  LegalDocumentType type;
  final TextEditingController labelController;
  PlatformFile? file;

  _LegalDocumentRow({this.type = LegalDocumentType.dtiPermit})
      : labelController = TextEditingController();

  void dispose() => labelController.dispose();
}

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _facebookPageUrlController = TextEditingController();

  // Backend requires at least one business type (`@NotEmpty
  // List<BusinessType> businessTypes`) - mirrors web's multi-select picker.
  final Set<BusinessType> _businessTypes = {};
  bool _acceptedTerms = false;
  PlatformFile? _logo;
  PlatformFile? _idCard;
  PlatformFile? _selfie;
  // Starts empty - unlike ID Card/Selfie, business-registration documents
  // are entirely optional and there can be any number of them.
  final List<_LegalDocumentRow> _legalDocumentRows = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _phoneNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _referralCodeController.dispose();
    _facebookPageUrlController.dispose();
    for (final row in _legalDocumentRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_businessTypes.isEmpty) {
      setState(() => _errorMessage = 'Select at least one business type.');
      return;
    }
    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'You must accept the vendor terms of service.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final request = VendorOnboardingRequest(
      businessName: _businessNameController.text.trim(),
      businessTypes: _businessTypes.toList(),
      ownerName: _nullIfEmpty(_ownerNameController.text),
      description: _nullIfEmpty(_descriptionController.text),
      contactEmail: _nullIfEmpty(_contactEmailController.text),
      phoneNumber: _nullIfEmpty(_phoneNumberController.text),
      addressLine1: _nullIfEmpty(_addressLine1Controller.text),
      addressLine2: _nullIfEmpty(_addressLine2Controller.text),
      city: _nullIfEmpty(_cityController.text),
      state: _nullIfEmpty(_stateController.text),
      postalCode: _nullIfEmpty(_postalCodeController.text),
      country: _nullIfEmpty(_countryController.text),
      facebookPageUrl: _nullIfEmpty(_facebookPageUrlController.text),
      acceptedTerms: _acceptedTerms,
      referralCode: _nullIfEmpty(_referralCodeController.text),
    );

    final legalDocuments = _legalDocumentRows
        .where((row) => row.file != null)
        .map((row) => LegalDocumentUpload(
              type: row.type,
              label: _nullIfEmpty(row.labelController.text),
              file: row.file!,
            ))
        .toList();

    try {
      final vendorApi = context.read<VendorApi>();
      final response = await vendorApi.becomeVendor(
        request: request,
        logo: _logo,
        idCard: _idCard,
        selfie: _selfie,
        legalDocuments: legalDocuments,
      );
      if (!mounted) return;
      await context.read<AuthController>().applyAuthResponse(response);
      if (!mounted) return;
      // Guarded: this screen is also reached directly as AuthGate's own
      // return value (a planner mid-vendor-onboarding, signupIntent vendor
      // but role not yet vendor - see AuthGate), where there's nothing on
      // the Navigator stack to pop. In that case AuthGate's own rebuild
      // (triggered by applyAuthResponse's notifyListeners, now role=vendor)
      // swaps this screen away on its own. When pushed from the "Become a
      // Vendor" button instead, popping still reveals the planner screen
      // beneath it as before.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroHeader(
                    logo: _logo,
                    onLogoChanged: (file) => setState(() => _logo = file),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    icon: Icons.storefront_outlined,
                    title: 'Business Info',
                    children: [
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Business Type(s)',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BusinessType.values
                            .map(
                              (type) => FilterChip(
                                label: Text(type.label),
                                selected: _businessTypes.contains(type),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _businessTypes.add(type);
                                  } else {
                                    _businessTypes.remove(type);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ),
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        // Backend requires this (`@NotBlank` on
                        // VendorOnboardingRequest.ownerName) - without this
                        // validator, submitting with it blank passes
                        // client-side validation and fails with a confusing
                        // server error instead.
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Referral (Optional)',
                    children: [
                      TextFormField(
                        controller: _referralCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Referral Code',
                          helperText: 'Were you referred by another vendor? Enter their code here.',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.contact_mail_outlined,
                    title: 'Contact',
                    children: [
                      TextFormField(
                        controller: _contactEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        // Backend requires this (`@NotBlank @Email` on
                        // VendorOnboardingRequest.contactEmail).
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return 'Required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        // Backend requires this (`@NotBlank` on
                        // VendorOnboardingRequest.phoneNumber).
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      TextFormField(
                        controller: _facebookPageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Facebook Page URL (Optional)',
                          hintText: 'https://facebook.com/yourbusiness',
                          prefixIcon: Icon(Icons.facebook_outlined),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    children: [
                      TextFormField(
                        controller: _addressLine1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1',
                        ),
                      ),
                      TextFormField(
                        controller: _addressLine2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 2',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Postal Code',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Identity Verification',
                    subtitle: 'Used to verify your business. Kept private.',
                    children: [
                      ImageUploadTile(
                        label: 'ID Card',
                        file: _idCard,
                        onChanged: (file) => setState(() => _idCard = file),
                      ),
                      ImageUploadTile(
                        label: 'Selfie',
                        file: _selfie,
                        onChanged: (file) => setState(() => _selfie = file),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.gavel_outlined,
                    title: 'Business Legal Documents',
                    subtitle: 'Optional - add as many as apply: DTI, SEC, '
                        "Mayor's Permit, Barangay Clearance, BIR, etc. "
                        'Shown to planners on your storefront.',
                    children: [
                      for (final row in _legalDocumentRows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<LegalDocumentType>(
                                        initialValue: row.type,
                                        decoration: const InputDecoration(
                                          labelText: 'Document Type',
                                        ),
                                        items: LegalDocumentType.values
                                            .map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(type.label),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (type) => setState(
                                          () => row.type = type ?? row.type,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      tooltip: 'Remove',
                                      onPressed: () => setState(() {
                                        row.dispose();
                                        _legalDocumentRows.remove(row);
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: row.labelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Label (Optional)',
                                    hintText: 'e.g., Fire Safety Certificate',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ImageUploadTile(
                                  label: 'Document File',
                                  file: row.file,
                                  onChanged: (file) => setState(() => row.file = file),
                                ),
                              ],
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _legalDocumentRows.add(_LegalDocumentRow()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Document'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _acceptedTerms,
                    onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I accept the vendor terms of service.'),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Submit Application'),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark/orange hero card, independent of the (light) ambient theme by design
/// — matches the vendor's brand reference regardless of app theme.
class _HeroHeader extends StatelessWidget {
  final PlatformFile? logo;
  final ValueChanged<PlatformFile?> onLogoChanged;

  const _HeroHeader({required this.logo, required this.onLogoChanged});

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      onLogoChanged(result.files.single);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1530), kBrandBlack],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kBrandOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FREE PRO TRIAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Become an EventsRUs Vendor',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get discovered by thousands of event planners — start with a free '
                  'PRO plan for 180 days.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: const [
                    _HeroStat(
                      icon: Icons.card_giftcard_outlined,
                      label: 'FREE TRIAL',
                      value: 'PRO, 180 days',
                    ),
                    _HeroStat(
                      icon: Icons.bolt_outlined,
                      label: 'SETUP TIME',
                      value: 'About 5 minutes',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          InkWell(
            onTap: _pickLogo,
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: logo?.bytes != null
                      ? Image.memory(logo!.bytes!, fit: BoxFit.cover)
                      : const Icon(
                          Icons.storefront,
                          size: 36,
                          color: kBrandBlack,
                        ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kBrandOrange,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
