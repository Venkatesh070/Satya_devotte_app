class AuthLoginResult {
  AuthLoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.isRegistered,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  /// When `false`, the client should collect profile details on [CreateAccountPage].
  final bool isRegistered;
}
