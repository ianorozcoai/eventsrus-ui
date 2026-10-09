import 'plan_tier.dart';
import 'role.dart';
import 'signup_intent.dart';

class AuthResponse {
  final String token;
  // Long-lived - exchanged for a fresh token pair via POST
  // /api/v1/auth/refresh once [token] expires, so the session can stay
  // signed in for weeks without a full re-login. See AuthController.
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final Role role;
  final SignupIntent? signupIntent;
  final String? firstName;
  final String? email;
  final PlanTier? plan;
  final DateTime? planExpiresAt;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.role,
    this.signupIntent,
    this.firstName,
    this.email,
    this.plan,
    this.planExpiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresIn: json['expiresIn'] as int,
        role: RoleApi.fromApi(json['role'] as String),
        signupIntent: SignupIntentApi.fromApiNullable(json['signupIntent'] as String?),
        firstName: json['firstName'] as String?,
        email: json['email'] as String?,
        plan: PlanTierApi.fromApiNullable(json['plan'] as String?),
        planExpiresAt: json['planExpiresAt'] == null
            ? null
            : DateTime.parse(json['planExpiresAt'] as String),
      );
}
