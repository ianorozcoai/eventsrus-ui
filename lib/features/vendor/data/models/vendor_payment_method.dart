import 'payment_method_status.dart';

/// Mirrors eventsrus-backend's {@code VendorPaymentMethodResponse}.
class VendorPaymentMethod {
  final int id;
  final String label;
  final String? qrImageUrl;
  final PaymentMethodStatus status;

  const VendorPaymentMethod({
    required this.id,
    required this.label,
    this.qrImageUrl,
    required this.status,
  });

  factory VendorPaymentMethod.fromJson(Map<String, dynamic> json) => VendorPaymentMethod(
        id: json['id'] as int,
        label: json['label'] as String,
        qrImageUrl: json['qrImageUrl'] as String?,
        status: PaymentMethodStatusApi.fromApi(json['status'] as String),
      );
}
