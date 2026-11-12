/// Builds the reset callback on the SAME My Fitness Date Flutter entry point.
/// Supabase Redirect URLs must allow the returned exact URL.
String passwordRecoveryRedirect(String redirectUrl) {
  final uri = Uri.tryParse(redirectUrl);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException('URL de recuperación insegura');
  }
  // A dedicated SPA route avoids relying on recovery events emitted
  // before Flutter's root widget subscribes to the auth stream.
  return '${uri.origin}/recover/';
}

String? passwordValidationMessage(String password, String confirmation) {
  if (password.length < 12 || password.length > 128) {
    return 'Utiliza entre 12 y 128 caracteres.';
  }
  if (password != confirmation) {
    return 'Las contraseñas no coinciden.';
  }
  return null;
}
