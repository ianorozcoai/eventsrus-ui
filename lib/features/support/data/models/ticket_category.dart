/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.TicketCategory}.
enum TicketCategory { transactionDispute, billing, technicalIssue, account, other }

extension TicketCategoryApi on TicketCategory {
  String toApi() {
    switch (this) {
      case TicketCategory.transactionDispute:
        return 'TRANSACTION_DISPUTE';
      case TicketCategory.billing:
        return 'BILLING';
      case TicketCategory.technicalIssue:
        return 'TECHNICAL_ISSUE';
      case TicketCategory.account:
        return 'ACCOUNT';
      case TicketCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case TicketCategory.transactionDispute:
        return 'Transaction Dispute';
      case TicketCategory.billing:
        return 'Billing';
      case TicketCategory.technicalIssue:
        return 'Technical Issue';
      case TicketCategory.account:
        return 'Account';
      case TicketCategory.other:
        return 'Other';
    }
  }

  static TicketCategory fromApi(String value) {
    switch (value) {
      case 'TRANSACTION_DISPUTE':
        return TicketCategory.transactionDispute;
      case 'BILLING':
        return TicketCategory.billing;
      case 'TECHNICAL_ISSUE':
        return TicketCategory.technicalIssue;
      case 'ACCOUNT':
        return TicketCategory.account;
      case 'OTHER':
        return TicketCategory.other;
      default:
        throw FormatException('Unknown ticket category: $value');
    }
  }
}
