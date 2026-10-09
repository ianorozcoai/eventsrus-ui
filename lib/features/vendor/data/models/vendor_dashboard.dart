class VendorDashboard {
  final int newLeadsCount;
  final int newMessagesCount;
  final int newQuotationsCount;
  final int newBookingsCount;
  final int upcomingEventsCount;
  final double totalIncome;
  final int cancellationsCount;
  final bool hasPackages;

  const VendorDashboard({
    required this.newLeadsCount,
    required this.newMessagesCount,
    required this.newQuotationsCount,
    required this.newBookingsCount,
    required this.upcomingEventsCount,
    required this.totalIncome,
    required this.cancellationsCount,
    required this.hasPackages,
  });

  factory VendorDashboard.fromJson(Map<String, dynamic> json) => VendorDashboard(
        newLeadsCount: json['newLeadsCount'] as int,
        // Backend's VendorDashboardResponse field is newInquiriesCount, not
        // newMessagesCount - the JSON key, not just this model's field name.
        newMessagesCount: json['newInquiriesCount'] as int,
        newQuotationsCount: json['newQuotationsCount'] as int,
        newBookingsCount: json['newBookingsCount'] as int,
        upcomingEventsCount: json['upcomingEventsCount'] as int,
        totalIncome: (json['totalIncome'] as num).toDouble(),
        cancellationsCount: json['cancellationsCount'] as int,
        hasPackages: json['hasPackages'] as bool,
      );
}
