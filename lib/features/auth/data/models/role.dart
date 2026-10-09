enum Role { planner, vendor, admin }

extension RoleApi on Role {
  String toApi() {
    switch (this) {
      case Role.planner:
        return 'PLANNER';
      case Role.vendor:
        return 'VENDOR';
      case Role.admin:
        return 'ADMIN';
    }
  }

  static Role fromApi(String value) {
    switch (value) {
      case 'PLANNER':
        return Role.planner;
      case 'VENDOR':
        return Role.vendor;
      case 'ADMIN':
        return Role.admin;
      default:
        throw FormatException('Unknown role: $value');
    }
  }
}
