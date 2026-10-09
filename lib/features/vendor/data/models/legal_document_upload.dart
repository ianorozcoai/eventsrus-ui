import 'package:file_picker/file_picker.dart';

import 'legal_document_type.dart';

/// One business-registration document row the vendor is attaching at
/// onboarding - a vendor can add any number of these (DTI, SEC, Mayor's
/// Permit, Barangay Clearance, BIR, ...), see VendorOnboardingScreen.
class LegalDocumentUpload {
  final LegalDocumentType type;
  final String? label;
  final PlatformFile file;

  const LegalDocumentUpload({
    required this.type,
    this.label,
    required this.file,
  });
}
