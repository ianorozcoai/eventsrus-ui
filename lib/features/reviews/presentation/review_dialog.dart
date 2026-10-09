import 'package:flutter/material.dart';

/// Result of [showReviewFormDialog] - null means the planner cancelled.
class ReviewFormResult {
  final int rating;
  final String comment;

  const ReviewFormResult({required this.rating, required this.comment});
}

/// Star rating + comment dialog, used both to leave a first review
/// (eventsrus-web's reviewModal "Post Review" state) and to edit an
/// existing one ("Update Review" state) - see planner/events.html.
Future<ReviewFormResult?> showReviewFormDialog(
  BuildContext context, {
  required String vendorLabel,
  int? initialRating,
  String? initialComment,
}) {
  int rating = initialRating ?? 5;
  final commentController = TextEditingController(text: initialComment ?? '');
  final isEdit = initialRating != null;

  return showDialog<ReviewFormResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(isEdit ? 'Edit Your Review - $vendorLabel' : 'Leave a Review - $vendorLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setDialogState(() => rating = i),
                  ),
              ],
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Your review'),
              maxLines: 4,
              maxLength: 2000,
              onChanged: (_) => setDialogState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: commentController.text.trim().isEmpty
                ? null
                : () => Navigator.of(dialogContext).pop(
                      ReviewFormResult(rating: rating, comment: commentController.text.trim()),
                    ),
            child: Text(isEdit ? 'Update Review' : 'Post Review'),
          ),
        ],
      ),
    ),
  );
}

/// Read-only star row for showing a rating (e.g. an existing review, or a
/// vendor's average).
class StarRatingRow extends StatelessWidget {
  final double rating;
  final double size;

  const StarRatingRow({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating.round() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
      ],
    );
  }
}
