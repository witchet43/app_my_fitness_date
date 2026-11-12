/// Validation for B1 minimal member onboarding. Date of birth is private,
/// never projected into activity cards or public profiles.
bool isDeclaredAdult(DateTime birthDate, DateTime now) {
  final years = now.year - birthDate.year;
  return years > 18 || (years == 18 &&
      (now.month > birthDate.month ||
       (now.month == birthDate.month && now.day >= birthDate.day)));
}

List<String> normalizedSports(String text) =>
    text.split(',').map((sport) => sport.trim())
        .where((sport) => sport.isNotEmpty).toSet().toList();

String? validateMemberBasics({
  required String name,
  required String city,
  required String sports,
  required DateTime? dateOfBirth,
  required bool adultDeclared,
  DateTime? now,
}) {
  if (name.trim().length < 2 || name.trim().length > 60) {
    return 'Escribe un nombre visible de 2 a 60 caracteres.';
  }
  if (city.trim().length < 2 || city.trim().length > 100) {
    return 'Escribe tu ciudad (sin domicilio ni ubicación exacta).';
  }
  final values = normalizedSports(sports);
  if (values.isEmpty || values.length > 16 ||
      values.any((v) => v.length < 2 || v.length > 40)) {
    return 'Escribe de 1 a 16 deportes separados por comas.';
  }
  if (!adultDeclared || dateOfBirth == null ||
      !isDeclaredAdult(dateOfBirth, now ?? DateTime.now())) {
    return 'Para continuar debes declarar y tener al menos 18 años.';
  }
  return null;
}

String dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
