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
}
