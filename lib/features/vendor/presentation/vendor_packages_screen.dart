import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/models/vendor_package.dart';
import '../../marketplace/data/models/vendor_package_group.dart';
import '../../marketplace/data/models/vendor_package_image.dart';
import '../../marketplace/data/vendor_package_api.dart';
import '../../marketplace/data/vendor_package_group_api.dart';
import '../../marketplace/data/vendor_package_image_api.dart';
import 'widgets/package_photo_grid.dart';

class VendorPackagesScreen extends StatefulWidget {
  const VendorPackagesScreen({super.key});

  @override
  State<VendorPackagesScreen> createState() => _VendorPackagesScreenState();
}

class _VendorPackagesScreenState extends State<VendorPackagesScreen> {
  List<VendorPackage>? _packages;
  List<VendorPackageGroup>? _groups;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        context.read<VendorPackageApi>().list(),
        context.read<VendorPackageGroupApi>().list(),
      ]);
      if (!mounted) return;
      setState(() {
        _packages = results[0] as List<VendorPackage>;
        _groups = results[1] as List<VendorPackageGroup>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openPackageForm({VendorPackage? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PackageFormDialog(existing: existing, allGroups: _groups ?? const []),
    );
    if (saved == true) await _load();
  }

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Group name', hintText: 'e.g., Weddings'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (!mounted) return;

    try {
      await context.read<VendorPackageGroupApi>().create(name);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteGroup(VendorPackageGroup group) async {
    final confirmed = await _confirmDialog(
      context,
      'Delete the group "${group.name}"? This removes it from every package it\'s applied to - the packages themselves are untouched.',
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorPackageGroupApi>().delete(group.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleActive(VendorPackage package) async {
    final confirmed = await _confirmDialog(
      context,
      package.active
          ? 'Discontinue "${package.name}"? It will be hidden from your storefront right away, but you can reactivate it anytime.'
          : 'Reactivate "${package.name}"? It will show up on your storefront again.',
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorPackageApi>().setActive(package.id, !package.active);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final packages = _packages ?? [];
    final groups = _groups ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPackageForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Package'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Listings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _GroupsCard(groups: groups, onAdd: _createGroup, onDelete: _deleteGroup),
            const SizedBox(height: 16),
            Expanded(
              child: packages.isEmpty
                  ? const Center(child: Text('No packages yet — add one so planners know what you offer.'))
                  : ListView.separated(
                      itemCount: packages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final package = packages[index];
                        return _PackageCard(
                          package: package,
                          onEdit: () => _openPackageForm(existing: package),
                          onToggleActive: () => _toggleActive(package),
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

/// Vendor-defined package groups - create/delete here, assigned to
/// individual packages from the Add/Edit Package form below. Deleting a
/// group only removes the association from any package it's applied to;
/// the packages themselves are untouched (see backend
/// VendorPackageGroupService#deleteGroup).
class _GroupsCard extends StatelessWidget {
  final List<VendorPackageGroup> groups;
  final VoidCallback onAdd;
  final ValueChanged<VendorPackageGroup> onDelete;

  const _GroupsCard({required this.groups, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Groups',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Group')),
              ],
            ),
            Text(
              'Planners can filter your storefront packages by group.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            if (groups.isEmpty)
              Text('No groups yet - add one above.', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: groups
                    .map(
                      (group) => Chip(
                        label: Text(group.name),
                        onDeleted: () => onDelete(group),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final VendorPackage package;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _PackageCard({
    required this.package,
    required this.onEdit,
    required this.onToggleActive,
  });

  String get _priceLabel {
    switch (package.pricingType) {
      case PackagePricingType.fixed:
        return package.price != null ? '₱${package.price!.toStringAsFixed(0)}' : 'No price set';
      case PackagePricingType.range:
        if (package.minPrice != null && package.maxPrice != null) {
          return '₱${package.minPrice!.toStringAsFixed(0)} - ₱${package.maxPrice!.toStringAsFixed(0)}';
        }
        return 'No price range set';
      case PackagePricingType.quote:
        return 'Request for Quotation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: package.active ? 1 : 0.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(package.packageType.label),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (!package.active) ...[
                    const SizedBox(width: 8),
                    const Chip(
                      label: Text('Inactive'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit package', onPressed: onEdit),
                  IconButton(
                    icon: Icon(package.active ? Icons.pause_circle_outline : Icons.restart_alt),
                    tooltip: package.active ? 'Discontinue package' : 'Reactivate package',
                    onPressed: onToggleActive,
                  ),
                ],
              ),
              Text(package.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (package.description != null && package.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(package.description!, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Text(_priceLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (package.groups.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: package.groups
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (package.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('${package.images.length} photo(s)', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Add/Edit Package - one dialog for both, matching eventsrus-web's single
/// per-package form (see packages.html). Groups are assigned here as
/// checkboxes/chips rather than web's separate "Edit Groups" modal, since a
/// mobile dialog can comfortably hold both without the extra round trip.
///
/// Photos behave differently depending on mode, same reasoning as web's
/// dropzone-queued-until-save vs. already-saved-is-immediate split:
/// - Editing an existing package: it already has an id, so a newly picked
///   photo uploads immediately and an existing photo's delete button is
///   immediate too (both with their own error handling inline).
/// - Creating a new package: there's no id yet, so picked photos are held
///   locally (_pendingImages) and only actually uploaded after the package
///   itself is created successfully.
class _PackageFormDialog extends StatefulWidget {
  final VendorPackage? existing;
  final List<VendorPackageGroup> allGroups;

  const _PackageFormDialog({required this.existing, required this.allGroups});

  @override
  State<_PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<_PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  late PackageType _packageType;
  late PackagePricingType _pricingType;
  late Set<int> _selectedGroupIds;
  late List<VendorPackageImage> _existingImages;
  final List<PlatformFile> _pendingImages = [];

  bool _submitting = false;
  bool _uploadingPhoto = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _priceController = TextEditingController(text: existing?.price?.toStringAsFixed(2) ?? '');
    _minPriceController = TextEditingController(text: existing?.minPrice?.toStringAsFixed(2) ?? '');
    _maxPriceController = TextEditingController(text: existing?.maxPrice?.toStringAsFixed(2) ?? '');
    _packageType = existing?.packageType ?? PackageType.service;
    _pricingType = existing?.pricingType ?? PackagePricingType.fixed;
    _existingImages = List.of(existing?.images ?? const []);
    // Matches by NAME, not id - the package response only carries group
    // names (see VendorPackage.groups' own doc comment), same convention
    // web's editGroupsCheckbox pre-check uses.
    final currentNames = existing?.groups.toSet() ?? <String>{};
    _selectedGroupIds = widget.allGroups.where((g) => currentNames.contains(g.name)).map((g) => g.id).toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    if (!_isEditing) {
      setState(() => _pendingImages.addAll(result.files));
      return;
    }
    if (!mounted) return;

    setState(() {
      _uploadingPhoto = true;
      _error = null;
    });
    final imageApi = context.read<VendorPackageImageApi>();
    for (final file in result.files) {
      try {
        final uploaded = await imageApi.upload(widget.existing!.id, file);
        if (!mounted) return;
        setState(() => _existingImages.add(uploaded));
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _error = e.message);
      }
    }
    if (mounted) setState(() => _uploadingPhoto = false);
  }

  Future<void> _deleteExistingPhoto(VendorPackageImage image) async {
    final confirmed = await _confirmDialog(context, 'Remove this photo permanently? This cannot be undone.');
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorPackageImageApi>().delete(widget.existing!.id, image.id);
      if (!mounted) return;
      setState(() => _existingImages.removeWhere((img) => img.id == image.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
    final price = _pricingType == PackagePricingType.fixed ? double.tryParse(_priceController.text.trim()) : null;
    final minPrice = _pricingType == PackagePricingType.range ? double.tryParse(_minPriceController.text.trim()) : null;
    final maxPrice = _pricingType == PackagePricingType.range ? double.tryParse(_maxPriceController.text.trim()) : null;

    final packageApi = context.read<VendorPackageApi>();
    final imageApi = context.read<VendorPackageImageApi>();

    try {
      final VendorPackage saved;
      if (_isEditing) {
        saved = await packageApi.update(
          id: widget.existing!.id,
          name: name,
          description: description,
          packageType: _packageType,
          pricingType: _pricingType,
          price: price,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
      } else {
        saved = await packageApi.create(
          name: name,
          description: description,
          packageType: _packageType,
          pricingType: _pricingType,
          price: price,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
      }

      await packageApi.setGroups(saved.id, _selectedGroupIds.toList());

      if (!_isEditing && _pendingImages.isNotEmpty) {
        for (final file in _pendingImages) {
          await imageApi.upload(saved.id, file);
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save this package. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Package' : 'Add Package'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Package Type', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PackageType.values
                    .map(
                      (type) => ChoiceChip(
                        label: Text(type.label),
                        selected: _packageType == type,
                        onSelected: (_) => setState(() => _packageType = type),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Pricing', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PackagePricingType.values
                    .map(
                      (type) => ChoiceChip(
                        label: Text(type.label),
                        selected: _pricingType == type,
                        onSelected: (_) => setState(() => _pricingType = type),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              if (_pricingType == PackagePricingType.fixed)
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              if (_pricingType == PackagePricingType.range)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceController,
                        decoration: const InputDecoration(labelText: 'Min Price', prefixText: '₱ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceController,
                        decoration: const InputDecoration(labelText: 'Max Price', prefixText: '₱ '),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
              if (_pricingType == PackagePricingType.quote)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Planners will see "Request for Quotation" instead of a price - they\'ll need to '
                    'message you directly to ask.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              if (widget.allGroups.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Groups', style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.allGroups.map((group) {
                    final selected = _selectedGroupIds.contains(group.id);
                    return FilterChip(
                      label: Text(group.name),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        if (value) {
                          _selectedGroupIds.add(group.id);
                        } else {
                          _selectedGroupIds.remove(group.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Photos', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              PackagePhotoGrid(images: _existingImages, onDelete: _deleteExistingPhoto),
              if (_pendingImages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pendingImages
                      .map(
                        (file) => PendingPackagePhotoThumb(
                          file: file,
                          onRemove: () => setState(() => _pendingImages.remove(file)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _uploadingPhoto ? null : _pickPhotos,
                icon: _uploadingPhoto
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_uploadingPhoto ? 'Uploading…' : 'Add Photos'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
