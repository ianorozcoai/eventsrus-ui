/// Mirrors eventsrus-backend's enums.LegalDocumentType, same names.
enum LegalDocumentType {
  dtiPermit,
  secRegistration,
  mayorsPermit,
  barangayClearance,
  birRegistration,
  other,
}

extension LegalDocumentTypeApi on LegalDocumentType {
  String toApi() {
    switch (this) {
      case LegalDocumentType.dtiPermit:
        return 'DTI_PERMIT';
      case LegalDocumentType.secRegistration:
        return 'SEC_REGISTRATION';
      case LegalDocumentType.mayorsPermit:
        return 'MAYORS_PERMIT';
      case LegalDocumentType.barangayClearance:
        return 'BARANGAY_CLEARANCE';
      case LegalDocumentType.birRegistration:
        return 'BIR_REGISTRATION';
      case LegalDocumentType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case LegalDocumentType.dtiPermit:
        return 'DTI Permit';
      case LegalDocumentType.secRegistration:
        return 'SEC Registration';
      case LegalDocumentType.mayorsPermit:
        return "Mayor's Permit";
      case LegalDocumentType.barangayClearance:
        return 'Barangay Clearance';
      case LegalDocumentType.birRegistration:
        return 'BIR Registration';
      case LegalDocumentType.other:
        return 'Other';
    }
  }

  static LegalDocumentType fromApi(String value) {
    switch (value) {
      case 'DTI_PERMIT':
        return LegalDocumentType.dtiPermit;
      case 'SEC_REGISTRATION':
        return LegalDocumentType.secRegistration;
      case 'MAYORS_PERMIT':
        return LegalDocumentType.mayorsPermit;
      case 'BARANGAY_CLEARANCE':
        return LegalDocumentType.barangayClearance;
      case 'BIR_REGISTRATION':
        return LegalDocumentType.birRegistration;
      case 'OTHER':
        return LegalDocumentType.other;
      default:
        throw FormatException('Unknown legal document type: $value');
    }
  }
}
