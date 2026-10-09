import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../marketplace/data/vendor_package_image_api.dart';
import '../data/models/gallery_photo_limit.dart';
import '../data/models/image_source.dart';
import '../data/models/vendor_image_tag.dart';
import '../data/models/vendor_tagged_image.dart';
import '../data/vendor_gallery_api.dart';
import '../data/vendor_image_tag_api.dart';

/// Mirrors eventsrus-web's vendor/gallery.html: an "Add Photos" upload card
/// (standalone sample-work photos not tied to any package) plus one "All
/// Images" grid below it showing EVERY image the vendor has - those
/// standalone photos and every package's own photos, combined (see backend
/// VendorImageTagService#listAllTaggableImages) - since that combined set
/// is also what a planner sees as this vendor's single storefront Gallery.
/// A package photo is tag-editable here but only uploadable/deletable from
/// the Packages screen - this page isn't where its lifecycle is managed,
/// just where it's organized alongside everything else.
class VendorGalleryScreen extends StatefulWidget {
  const VendorGalleryScreen({super.key});

  @override
  State<VendorGalleryScreen> createState() => _VendorGalleryScreenState();
}

class _VendorGalleryScreenState extends State<VendorGalleryScreen> {
  List<VendorTaggedImage>? _images;
  List<VendorImageTag>? _tags;
  GalleryPhotoLimit? _limit;
  bool _loading = true;

  // 'All', 'Untagged', or a tag name - same three-way filter as web's
  // dropdown, as chips instead (consistent with this app's other filter
  // rows, e.g. VendorStorefrontScreen's gallery/package group chips).
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        context.read<VendorImageTagApi>().images(),
        context.read<VendorImageTagApi>().list(),
        context.read<VendorGalleryApi>().limit(),
      ]);
      if (!mounted) return;
      setState(() {
        _images = results[0] as List<VendorTaggedImage>;
        _tags = results[1] as List<VendorImageTag>;
        _limit = results[2] as GalleryPhotoLimit;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tag name', hintText: 'e.g., Weddings'),
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
      await context.read<VendorImageTagApi>().create(name);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteTag(VendorImageTag tag) async {
    final confirmed = await _confirmDialog(
      context,
      'Delete the tag "${tag.name}"? This removes it from every photo it\'s applied to - the photos themselves are untouched.',
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorImageTagApi>().delete(tag.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // Matches eventsrus-web's dropzone exactly: tap straight into the photo
  // picker, select one or more, each uploads immediately - no caption step
  // (that field is a real but web-side-unused backend option; neither app
  // surfaces it) and no intermediate confirm dialog.
  Future<void> _addPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 16),
            Text(result.files.length > 1 ? 'Uploading ${result.files.length} photos…' : 'Uploading photo…'),
          ],
        ),
      ),
    );

    String? error;
    final galleryApi = context.read<VendorGalleryApi>();
    for (final file in result.files) {
      try {
        await galleryApi.upload(file);
      } on ApiException catch (e) {
        error = e.message;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    await _load();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _deletePhoto(VendorTaggedImage image) async {
    final confirmed = await _confirmDialog(context, 'Remove this photo permanently? This cannot be undone.');
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await context.read<VendorGalleryApi>().delete(image.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _manageTags(VendorTaggedImage image) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ManageTagsDialog(image: image, allTags: _tags ?? const []),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final images = _images ?? const [];
    final tags = _tags ?? const [];
    final limit = _limit;
    final limitReached = limit?.isReached ?? false;

    final filterOptions = ['All', 'Untagged', ...tags.map((t) => t.name)];
    final filteredImages = switch (_filter) {
      'All' => images,
      'Untagged' => images.where((img) => img.tags.isEmpty).toList(),
      final tagName => images.where((img) => img.tags.any((t) => t.name == tagName)).toList(),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Gallery', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Sample-work photos for your storefront that aren\'t tied to a specific package.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 20),
            _TagsCard(tags: tags, onAdd: _addTag, onDelete: _deleteTag),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Add Photos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: limitReached ? null : _addPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Photo'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (limit != null)
              Text(
                '${limit.used} of ${limit.limit} standalone photos used.',
                style: TextStyle(
                  color: limitReached ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outline,
                  fontWeight: limitReached ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            if (limitReached)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text("You've reached your standalone photo limit. Delete a photo below to add a new one."),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('All Images', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Standalone photos and every package\'s own photos, combined - the same set planners see on your storefront.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 8),
            if (images.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in filterOptions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: _filter == option,
                          onSelected: (_) => setState(() => _filter = option),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (images.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No images yet. Add photos above, or attach photos to a package.')),
              )
            else if (filteredImages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No photos match this filter.')),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: filteredImages.length,
                itemBuilder: (context, index) => _TaggedImageCard(
                  image: filteredImages[index],
                  tagsAvailable: tags.isNotEmpty,
                  onDelete: () => _deletePhoto(filteredImages[index]),
                  onManageTags: () => _manageTags(filteredImages[index]),
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

/// Vendor-created tags, shared across every gallery photo - create/delete
/// here, applied per-photo via each card's "Manage tags" button. Deleting a
/// tag only removes the association from any photo it's applied to; the
/// photos themselves are untouched (matches backend
/// VendorImageTagService#deleteTag).
class _TagsCard extends StatelessWidget {
  final List<VendorImageTag> tags;
  final VoidCallback onAdd;
  final ValueChanged<VendorImageTag> onDelete;

  const _TagsCard({required this.tags, required this.onAdd, required this.onDelete});

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
                Text('Tags', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Tag')),
              ],
            ),
            Text(
              'Create tags and apply them to your photos below - planners can filter your storefront gallery by tag.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            if (tags.isEmpty)
              Text('No tags yet - add one above.', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag.name),
                        onDeleted: () => onDelete(tag),
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

class _TaggedImageCard extends StatelessWidget {
  final VendorTaggedImage image;
  final bool tagsAvailable;
  final VoidCallback onDelete;
  final VoidCallback onManageTags;

  const _TaggedImageCard({
    required this.image,
    required this.tagsAvailable,
    required this.onDelete,
    required this.onManageTags,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Image.network(
              image.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 40),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.source == ImageSource.package ? 'Package: ${image.packageName}' : 'Standalone photo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (image.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: image.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag.name, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sell_outlined, size: 20),
                        tooltip: tagsAvailable ? 'Manage tags' : 'Create a tag above first',
                        onPressed: tagsAvailable ? onManageTags : null,
                        visualDensity: VisualDensity.compact,
                      ),
                      // Only standalone photos' lifecycle is managed here -
                      // a package photo is uploaded/deleted from the
                      // Packages screen instead (see this file's own doc
                      // comment).
                      if (image.source == ImageSource.gallery)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Remove photo',
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared single modal for editing one image's tags at a time - matches
/// eventsrus-web's gallery.html "Edit Tags" modal (one modal, re-populated
/// per click, rather than one dialog instance per image). Routes the save
/// to the correct endpoint based on the image's source, same branch web's
/// own JS makes (see gallery.html's edit-tags-btn handler).
class _ManageTagsDialog extends StatefulWidget {
  final VendorTaggedImage image;
  final List<VendorImageTag> allTags;

  const _ManageTagsDialog({required this.image, required this.allTags});

  @override
  State<_ManageTagsDialog> createState() => _ManageTagsDialogState();
}

class _ManageTagsDialogState extends State<_ManageTagsDialog> {
  late Set<int> _selectedTagIds;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = widget.image.tags.map((tag) => tag.id).toSet();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final image = widget.image;
      if (image.source == ImageSource.package) {
        await context.read<VendorPackageImageApi>().setTags(image.packageId!, image.id, _selectedTagIds.toList());
      } else {
        await context.read<VendorGalleryApi>().setTags(image.id, _selectedTagIds.toList());
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Tags'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.allTags.map(
              (tag) => CheckboxListTile(
                value: _selectedTagIds.contains(tag.id),
                title: Text(tag.name),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selectedTagIds.add(tag.id);
                  } else {
                    _selectedTagIds.remove(tag.id);
                  }
                }),
              ),
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
