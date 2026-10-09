class GoogleAuthRequest {
  final String idToken;
  // "PLANNER" or "VENDOR" - which login door was used, matching
  // eventsrus-web's role-picker. See backend GoogleAuthRequest's own doc
  // comment: missing/null skips the identity-lock check entirely rather
  // than defaulting to either side.
  final String? intent;

  const GoogleAuthRequest({required this.idToken, this.intent});

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        if (intent != null) 'intent': intent,
      };
}
