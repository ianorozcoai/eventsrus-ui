import 'package:flutter/material.dart';

/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.PaymentMethodStatus}.
enum PaymentMethodStatus { pending, approved, rejected }

extension PaymentMethodStatusApi on PaymentMethodStatus {
  String get label {
    switch (this) {
      case PaymentMethodStatus.pending:
        return 'Pending';
      case PaymentMethodStatus.approved:
        return 'Approved';
      case PaymentMethodStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethodStatus.pending:
        return Colors.orange;
      case PaymentMethodStatus.approved:
        return Colors.green;
      case PaymentMethodStatus.rejected:
        return Colors.red;
    }
  }

  static PaymentMethodStatus fromApi(String value) {
    switch (value) {
      case 'PENDING':
        return PaymentMethodStatus.pending;
      case 'APPROVED':
        return PaymentMethodStatus.approved;
      case 'REJECTED':
        return PaymentMethodStatus.rejected;
      default:
        throw FormatException('Unknown payment method status: $value');
    }
  }
}
