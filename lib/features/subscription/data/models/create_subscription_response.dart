class CreateSubscriptionResponse {
  final int vendorSubscriptionId;
  final String approvalUrl;

  const CreateSubscriptionResponse({
    required this.vendorSubscriptionId,
    required this.approvalUrl,
  });

  factory CreateSubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      CreateSubscriptionResponse(
        vendorSubscriptionId: json['vendorSubscriptionId'] as int,
        approvalUrl: json['approvalUrl'] as String,
      );
}
