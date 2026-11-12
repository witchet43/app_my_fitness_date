import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/password_recovery.dart';

void main() {
  test('password recovery returns to the same Flutter app', () {
    expect(passwordRecoveryRedirect('https://my-fitness-date.pages.dev/'),
      'https://my-fitness-date.pages.dev/recover/');
    expect(passwordRecoveryRedirect('https://example.test/?a=1'),
      'https://example.test/recover/');
  });

  test('only HTTPS callback URLs are accepted', () {
    expect(() => passwordRecoveryRedirect('http://example.test/'),
      throwsFormatException);
    expect(() => passwordRecoveryRedirect('javascript:alert(1)'),
      throwsFormatException);
  });

  test('new passwords require a long matching confirmation', () {
    expect(passwordValidationMessage('short', 'short'),
      'Utiliza entre 12 y 128 caracteres.');
    expect(passwordValidationMessage('a-long-password-123',
      'a-long-password-124'), 'Las contraseñas no coinciden.');
    expect(passwordValidationMessage('a-long-password-123',
      'a-long-password-123'), isNull);
  });
  test('Supabase same_password is not misreported as an expired link', () {
    const detail = 'New password should be different from the old password.';
    expect(passwordAlreadyInUse(detail), isTrue);
    expect(passwordAlreadyInUse('same_password'), isTrue);
    expect(safeRecoveryErrorMessage(detail),
      'Esta contraseña ya es la actual de tu cuenta. '
      'Utiliza otra diferente o vuelve a iniciar sesión con ella.');
  });

  test('Expired and weak-password errors remain distinct and safe', () {
    expect(safeRecoveryErrorMessage('invalid jwt'),
      contains('caducado'));
    expect(safeRecoveryErrorMessage('weak_password'),
      contains('seguridad'));
    expect(safeRecoveryErrorMessage('Unexpected backend: token abc123'),
      isNot(contains('abc123')));
  });

}
