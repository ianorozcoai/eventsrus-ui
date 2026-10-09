import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared "open this document/image" helpers for the quotation/booking
/// lifecycle screens - quote PDFs, reference/response images, payment
/// screenshots, invoices, and free-form attachments all funnel through
/// here instead of each screen reinventing how to show a URL. Images open
/// in-app (same InteractiveViewer lightbox pattern already used by
/// conversation_thread_screen.dart/vendor_storefront_screen.dart); PDFs and
/// anything else open via the external viewer (same pattern already used
/// by vendor_settings_screen.dart for policy documents - there's no in-app
/// PDF renderer in this app).
void showImageViewer(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: InteractiveViewer(child: Image.network(imageUrl)),
    ),
  );
}

Future<void> openDocument(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Opens [url] the right way for [fileType] - the backend's own
/// discriminator ("IMAGE"/"PDF", see QuotationAttachmentFileType) for a
/// free-form attachment whose type isn't otherwise known up front. Falls
/// back to the external viewer for anything not explicitly "IMAGE".
Future<void> openAttachment(
  BuildContext context,
  String url, {
  String? fileType,
}) async {
  if (fileType == 'IMAGE') {
    showImageViewer(context, url);
    return;
  }
  await openDocument(url);
}

/// A grid of every image in [imageUrls], each tappable into the full-screen
/// viewer - used for "View Reference Images"/"View My Attached Images"
/// menu actions, where there can be more than one.
void showImageGalleryDialog(
  BuildContext context,
  String title,
  List<String> imageUrls,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: imageUrls.length,
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => showImageViewer(context, imageUrls[index]),
              child: Image.network(imageUrls[index], fit: BoxFit.cover),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// A row of small square thumbnails (reference/response images) - tapping
/// one opens the full-screen viewer. Used wherever a quotation shows a set
/// of planner-attached or vendor-attached images.
class ImageThumbnailRow extends StatelessWidget {
  final List<String> imageUrls;

  const ImageThumbnailRow({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => showImageViewer(context, imageUrls[index]),
            child: Image.network(
              imageUrls[index],
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single "View X" text-button, matching vendor_settings_screen.dart's
/// own document-link style, for a quote PDF / payment screenshot / invoice
/// wherever a quotation or booking row needs one.
class DocumentLinkButton extends StatelessWidget {
  final String label;
  final String url;
  final bool isImage;

  const DocumentLinkButton({
    super.key,
    required this.label,
    required this.url,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () =>
          isImage ? showImageViewer(context, url) : openDocument(url),
      icon: Icon(
        isImage ? Icons.image_outlined : Icons.description_outlined,
        size: 18,
      ),
      label: Text(label),
    );
  }
}
