/// B9: deterministic presentation-only search over the authenticated B1
/// catalogue. This is not an authorization mechanism: the server must still
/// validate RSVP ownership, organizer permissions and activity visibility.
String normalizeActivitySearchB9(String value) {
  var normalized = value.toLowerCase().trim();
  const accents = <String, String>{
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'ü': 'u',
  };
  for (final entry in accents.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}

List<String> activityFilterOptionsB9(
  Iterable<Map<String, dynamic>> activities,
  String field,
) {
  if (field != 'sport' && field != 'city') {
    throw ArgumentError.value(field, 'field', 'Only public fields are allowed');
  }
  final values = <String>{};
  for (final activity in activities) {
    if (activity['event_cancelled'] == true) continue;
    final value = (activity[field] ?? '').toString().trim();
    if (value.isNotEmpty && value.length <= 100) values.add(value);
  }
  return values.toList()
    ..sort((a, b) => normalizeActivitySearchB9(a)
        .compareTo(normalizeActivitySearchB9(b)));
}

List<Map<String, dynamic>> discoverActivitiesB9({
  required Iterable<Map<String, dynamic>> activities,
  required DateTime now,
  String query = '',
  String sport = '',
  String city = '',
  bool upcomingOnly = true,
}) {
  final text = normalizeActivitySearchB9(query);
  final sportTerm = normalizeActivitySearchB9(sport);
  final cityTerm = normalizeActivitySearchB9(city);
  final selected = <MapEntry<int, Map<String, dynamic>>>[];
  var index = 0;
  for (final activity in activities) {
    final position = index++;
    // A cancelled event is never bookable even if an API cache included it.
    if (activity['event_cancelled'] == true) continue;
    final date = DateTime.tryParse(
      (activity['starts_at'] ?? '').toString(),
    );
    if (upcomingOnly && (date == null || !date.isAfter(now))) continue;
    final title = normalizeActivitySearchB9(
      (activity['title'] ?? '').toString(),
    );
    final discipline = normalizeActivitySearchB9(
      (activity['sport'] ?? '').toString(),
    );
    final location = normalizeActivitySearchB9(
      (activity['city'] ?? '').toString(),
    );
    if (text.isNotEmpty &&
        !title.contains(text) &&
        !discipline.contains(text) &&
        !location.contains(text)) continue;
    if (sportTerm.isNotEmpty && discipline != sportTerm) continue;
    if (cityTerm.isNotEmpty && location != cityTerm) continue;
    selected.add(MapEntry(position, activity));
  }

  DateTime? starts(Map<String, dynamic> a) =>
      DateTime.tryParse((a['starts_at'] ?? '').toString());

  selected.sort((a, b) {
    final left = starts(a.value);
    final right = starts(b.value);
    final leftUpcoming = left != null && left.isAfter(now);
    final rightUpcoming = right != null && right.isAfter(now);
    if (leftUpcoming != rightUpcoming) return leftUpcoming ? -1 : 1;
    if (left == null && right != null) return 1;
    if (left != null && right == null) return -1;
    if (left != null && right != null) {
      final comparison = leftUpcoming
          ? left.compareTo(right)
          : right.compareTo(left);
      if (comparison != 0) return comparison;
    }
    return a.key.compareTo(b.key);
  });
  return List<Map<String, dynamic>>.unmodifiable(
    selected.map((entry) => entry.value),
  );
}
