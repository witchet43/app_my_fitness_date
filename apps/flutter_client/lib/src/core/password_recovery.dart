/// Builds the reset callback on the SAME My Fitness Date Flutter entry point.
/// Supabase Redirect URLs must allow the returned exact URL.
String passwordRecoveryRedirect(String redirectUrl) {
  final uri = Uri.tryParse(redirectUrl);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException('URL de recuperación insegura');
  }
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'password_reset': '1',
  }).toString();
}
