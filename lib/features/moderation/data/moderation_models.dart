/// What a report points at - mirrors eventsrus-backend's ReportContentType.
/// For [storefront] and [user] the content id is the other person's user id.
enum ReportContentType { message, review, storefront, user }

extension ReportContentTypeApi on ReportContentType {
  String toApi() {
    switch (this) {
      case ReportContentType.message:
        return 'MESSAGE';
      case ReportContentType.review:
        return 'REVIEW';
      case ReportContentType.storefront:
        return 'STOREFRONT';
      case ReportContentType.user:
        return 'USER';
    }
  }
}

/// Mirrors eventsrus-backend's ReportReason.
enum ReportReason { spam, harassment, fraudOrScam, inappropriate, other }

extension ReportReasonApi on ReportReason {
  String toApi() {
    switch (this) {
      case ReportReason.spam:
        return 'SPAM';
      case ReportReason.harassment:
        return 'HARASSMENT';
      case ReportReason.fraudOrScam:
        return 'FRAUD_OR_SCAM';
      case ReportReason.inappropriate:
        return 'INAPPROPRIATE';
      case ReportReason.other:
        return 'OTHER';
    }
  }

  /// Plain-language label shown in the report dialog.
  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'Spam or unwanted promotion';
      case ReportReason.harassment:
        return 'Harassment or abusive language';
      case ReportReason.fraudOrScam:
        return 'Fraud or a scam';
      case ReportReason.inappropriate:
        return 'Inappropriate content';
      case ReportReason.other:
        return 'Something else';
    }
  }
}

/// A person the signed-in user has blocked.
class BlockedUser {
  final int userId;
  final String displayName;
  final DateTime blockedAt;

  const BlockedUser({required this.userId, required this.displayName, required this.blockedAt});

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        userId: json['userId'] as int,
        displayName: json['displayName'] as String,
        blockedAt: DateTime.parse(json['blockedAt'] as String),
      );
}
