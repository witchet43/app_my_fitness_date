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

bool passwordAlreadyInUse(String serverMessage) {
  final detail = serverMessage.toLowerCase();
  return detail.contains('same_password') ||
      detail.contains('new password should be different from the old password');
}

/// Never display raw Auth server messages, tokens or account identifiers.
String safeRecoveryErrorMessage(String serverMessage) {
  final detail = serverMessage.toLowerCase();
  if (passwordAlreadyInUse(detail)) {
    return 'Esta contraseña ya es la actual de tu cuenta. '
        'Utiliza otra diferente o vuelve a iniciar sesión con ella.';
  }
  if (detail.contains('expired') ||
      detail.contains('invalid token') ||
      detail.contains('invalid jwt') ||
      detail.contains('session_not_found') ||
      detail.contains('session not found')) {
    return 'El enlace ya no es válido o ha caducado. '
        'Solicita uno nuevo desde el inicio de sesión.';
  }
  if (detail.contains('weak_password') ||
      detail.contains('password should contain') ||
      detail.contains('password should be at least')) {
    return 'La contraseña no cumple los requisitos de seguridad. '
        'Elige otra contraseña más segura.';
  }
  return 'No se pudo actualizar la contraseña. '
      'Comprueba tu conexión y reintenta. Si persiste, solicita otro enlace.';
}
