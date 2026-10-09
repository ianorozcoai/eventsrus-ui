import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../marketplace/data/models/vendor_package_image.dart';

/// Grid of a package's already-saved photos, each removable via [onDelete].
/// Deliberately separate from `ImageUploadTile` (single local file, used by
/// vendor onboarding for one ID/selfie/logo at a time) - a package can have
/// several already-uploaded network photos at once, so the shape doesn't
/// fit that widget.
class PackagePhotoGrid extends StatelessWidget {
  final List<VendorPackageImage> images;
  final ValueChanged<VendorPackageImage> onDelete;

  const PackagePhotoGrid({super.key, required this.images, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Text(
        'No photos yet.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((image) => _PhotoThumb(onDelete: () => onDelete(image), child: _NetworkThumb(image: image))).toList(),
    );
  }
}

/// One not-yet-uploaded photo queued in the Add Package form - a brand new
/// package has no id yet to upload against, so these are held locally and
/// only actually uploaded once the package itself is created. Removable
/// before Save.
class PendingPackagePhotoThumb extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const PendingPackagePhotoThumb({super.key, required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return _PhotoThumb(
      onDelete: onRemove,
      child: file.bytes != null
          ? Image.memory(file.bytes!, width: 72, height: 72, fit: BoxFit.cover)
          : _ThumbPlaceholder(icon: Icons.image_outlined),
    );
  }
}

class _NetworkThumb extends StatelessWidget {
  final VendorPackageImage image;

  const _NetworkThumb({required this.image});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      image.imageUrl,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _ThumbPlaceholder(icon: Icons.broken_image_outlined),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  final IconData icon;

  const _ThumbPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(icon, color: Theme.of(context).colorScheme.outline),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _PhotoThumb({required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
