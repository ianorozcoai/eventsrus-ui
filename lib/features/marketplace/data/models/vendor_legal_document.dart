import '../../../vendor/data/models/legal_document_type.dart';

/// Mirrors eventsrus-backend's {@code VendorLegalDocumentResponse} - a
/// business-registration document (DTI, SEC, Mayor's Permit, ...) shown on
/// the storefront. Business paperwork is safe to show directly, unlike the
/// ID card/selfie behind VendorPublicProfile.identityVerified, which stays
/// a yes/no summary only - see that field's own doc comment.
class VendorLegalDocument {
  final int id;
  final LegalDocumentType documentType;
  final String? label;
  final String url;

  const VendorLegalDocument({required this.id, required this.documentType, this.label, required this.url});

  factory VendorLegalDocument.fromJson(Map<String, dynamic> json) => VendorLegalDocument(
        id: json['id'] as int,
        documentType: LegalDocumentTypeApi.fromApi(json['documentType'] as String),
        label: json['label'] as String?,
        url: json['url'] as String,
      );
}
