/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.TicketStatus}.
enum TicketStatus { open, inProgress, resolved, closed }

extension TicketStatusApi on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  static TicketStatus fromApi(String value) {
    switch (value) {
      case 'OPEN':
        return TicketStatus.open;
      case 'IN_PROGRESS':
        return TicketStatus.inProgress;
      case 'RESOLVED':
        return TicketStatus.resolved;
      case 'CLOSED':
        return TicketStatus.closed;
      default:
        throw FormatException('Unknown ticket status: $value');
    }
  }
}
