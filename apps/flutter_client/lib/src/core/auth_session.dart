/// QA sessions are intentionally memory-only. Never serialize or log tokens.
class IdentityUser {
  const IdentityUser({
    required this.id,
    required this.email,
    required this.emailVerified,
  });

  final String id;
  final String email;
  final bool emailVerified;

  factory IdentityUser.fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final email = data['email'];
    final verified = data['email_verified'];
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (id is! String || !uuid.hasMatch(id) || email is! String ||
        !email.contains('@') || verified != true) {
      throw const FormatException('Invalid authenticated identity');
    }
    return IdentityUser(id: id, email: email, emailVerified: true);
  }
}

class IdentitySession {
  IdentitySession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final IdentityUser user;

  factory IdentitySession.fromJson(Map<String, dynamic> data) {
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    final expiry = data['expires_in'];
    if (access is! String || access.isEmpty || refresh is! String ||
        refresh.isEmpty || expiry is! int || expiry <= 0 || expiry > 86400 ||
        data['user'] is! Map) {
      throw const FormatException('Invalid identity session');
    }
    return IdentitySession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiry)),
      user: IdentityUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }
}

class IdentityException implements Exception {
  const IdentityException(this.safeMessage);

  /// A generic, non-identifying message. Never includes credentials or tokens.
  final String safeMessage;

  @override
  String toString() => safeMessage;
}
