import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/member_onboarding_validation.dart';

void main() {
  test('adult check uses exact birth month and day, not a rounded year', () {
    final today = DateTime(2026, 11, 12);
    expect(isDeclaredAdult(DateTime(2008, 11, 12), today), isTrue);
    expect(isDeclaredAdult(DateTime(2008, 11, 13), today), isFalse);
    expect(isDeclaredAdult(DateTime(1990, 5, 30), today), isTrue);
  });

  test('minimal profile rejects minors and empty sports', () {
    final today = DateTime(2026, 11, 12);
    expect(validateMemberBasics(
      name: 'Carla', city: 'Querétaro', sports: 'correr',
      dateOfBirth: DateTime(2008, 11, 13),
      adultDeclared: true, now: today,
    ), contains('18 años'));
    expect(validateMemberBasics(
      name: 'Carla', city: 'Querétaro', sports: ' ',
      dateOfBirth: DateTime(1990, 3, 10),
      adultDeclared: true, now: today,
    ), contains('deportes'));
    expect(validateMemberBasics(
      name: 'Carla', city: 'Querétaro', sports: 'correr, nadar',
      dateOfBirth: DateTime(1990, 3, 10),
      adultDeclared: true, now: today,
    ), isNull);
  });

  test('sports are normalized and private date serializes as ISO date', () {
    expect(normalizedSports(' correr, senderismo, correr ,, ciclismo '),
      ['correr', 'senderismo', 'ciclismo']);
    expect(dateOnly(DateTime(1990, 4, 9)), '1990-04-09');
  });
}
