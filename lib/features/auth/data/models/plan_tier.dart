enum PlanTier { pro }

extension PlanTierApi on PlanTier {
  String toApi() {
    switch (this) {
      case PlanTier.pro:
        return 'PRO';
    }
  }

  static PlanTier fromApi(String value) {
    switch (value) {
      case 'PRO':
        return PlanTier.pro;
      default:
        throw FormatException('Unknown plan tier: $value');
    }
  }

  static PlanTier? fromApiNullable(String? value) =>
      value == null ? null : fromApi(value);
}
