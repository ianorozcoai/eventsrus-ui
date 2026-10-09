import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImageUploadTile extends StatelessWidget {
  final String label;
  final PlatformFile? file;
  final ValueChanged<PlatformFile?> onChanged;

  const ImageUploadTile({
    super.key,
    required this.label,
    required this.file,
    required this.onChanged,
  });

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      onChanged(result.files.single);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFile = file?.bytes != null;

    return InkWell(
      onTap: _pick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
            color: hasFile ? colorScheme.primary : colorScheme.outlineVariant,
            width: hasFile ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasFile
                  ? Image.memory(file!.bytes!, fit: BoxFit.cover)
                  : Icon(Icons.add_photo_alternate_outlined, color: colorScheme.outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    hasFile ? file!.name : 'Tap to upload',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasFile ? colorScheme.onSurfaceVariant : colorScheme.outline,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_outlined,
              color: hasFile ? colorScheme.primary : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
