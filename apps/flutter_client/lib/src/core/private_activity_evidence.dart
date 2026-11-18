import 'dart:convert';

/// A local, non-generative description of a voluntarily supplied activity file.
/// No Strava API or MCP is accessed and no activity routes are retained.
class PrivateActivityEvidence {
  const PrivateActivityEvidence({
    required this.sessions,
    required this.activeDays,
    required this.activeWeeks,
    required this.averageDaysPerWeek,
    required this.primarySport,
    required this.primarySportShare,
    required this.summaryEs,
    required this.summaryEn,
    required this.importedAt,
  });

  final int sessions;
  final int activeDays;
  final int activeWeeks;
  final double averageDaysPerWeek;
  final String primarySport;
  final double primarySportShare;
  final String summaryEs;
  final String summaryEn;
  final DateTime importedAt;

  Map<String, dynamic> toJson() => {
    'sessions': sessions,
    'active_days': activeDays,
    'active_weeks': activeWeeks,
    'average_days_per_week': averageDaysPerWeek,
    'primary_sport': primarySport,
    'primary_sport_share': primarySportShare,
    'summary_es': summaryEs,
    'summary_en': summaryEn,
    'imported_at': importedAt.toIso8601String(),
  };

  factory PrivateActivityEvidence.fromJson(Map<String, dynamic> data) =>
      PrivateActivityEvidence(
        sessions: (data['sessions'] as num).toInt(),
        activeDays: (data['active_days'] as num).toInt(),
        activeWeeks: (data['active_weeks'] as num).toInt(),
        averageDaysPerWeek: (data['average_days_per_week'] as num).toDouble(),
        primarySport: data['primary_sport'] as String,
        primarySportShare: (data['primary_sport_share'] as num).toDouble(),
        summaryEs: data['summary_es'] as String,
        summaryEn: data['summary_en'] as String,
        importedAt: DateTime.parse(data['imported_at'] as String),
      );
}

/// Reads only Activity ID, Activity Date and Activity Type from activities.csv.
/// This intentionally does not ingest maps, location, health or GPS columns.
class PrivateActivityEvidenceAnalyzer {
  static PrivateActivityEvidence analyze(String source, {DateTime? today}) {
    final reference = today ?? DateTime.now();
    final day = DateTime(reference.year, reference.month, reference.day);
    final start = day.subtract(const Duration(days: 89));
    final rows = _csv(source);
    if (rows.length < 2) {
      throw const FormatException('El archivo no contiene actividades.');
    }
    final headers = rows.first
        .map((value) => value.replaceFirst('\uFEFF', '').trim().toLowerCase())
        .toList();
    final dateIndex = headers.indexOf('activity date');
    final typeIndex = headers.indexOf('activity type');
    final idIndex = headers.indexOf('activity id');
    if (dateIndex < 0 || typeIndex < 0) {
      throw const FormatException(
        'Se requiere activities.csv con Activity Date y Activity Type.');
    }

    final dedupe = <String>{};
    final sports = <String, int>{};
    final dates = <DateTime>{};
    final weeks = <int>{};
    var count = 0;
    for (final values in rows.skip(1)) {
      if (values.length <= dateIndex || values.length <= typeIndex) continue;
      final parsed = _date(values[dateIndex]);
      if (parsed == null) continue;
      final activityDay = DateTime(parsed.year, parsed.month, parsed.day);
      if (activityDay.isBefore(start) || activityDay.isAfter(day)) continue;
      final rawType = values[typeIndex].trim();
      if (rawType.isEmpty) continue;
      final id = idIndex >= 0 && idIndex < values.length
          ? values[idIndex].trim()
          : '';
      final identifier = id.isNotEmpty
          ? id
          : activityDay.toIso8601String() + ':' + rawType + ':' + count.toString();
      if (!dedupe.add(identifier)) continue;
      count++;
      dates.add(activityDay);
      final weekIndex = activityDay.difference(start).inDays ~/ 7;
      weeks.add(weekIndex);
      final sport = _sport(rawType);
      sports[sport] = (sports[sport] ?? 0) + 1;
    }
    if (count == 0) {
      throw const FormatException(
        'No hay actividades válidas dentro de los últimos 90 días.');
    }
    final ranking = sports.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final leading = ranking.first;
    final share = leading.value / count;
    final average = dates.length / (90 / 7);
    final frequencyEs = average >= 3
        ? 'Se mantiene muy activo'
        : average >= 1.5
            ? 'Mantiene una rutina activa'
            : 'Registra actividad física ocasional';
    final frequencyEn = average >= 3
        ? 'Shows a highly active routine'
        : average >= 1.5
            ? 'Maintains an active routine'
            : 'Records occasional physical activity';
    final consistencyEs = weeks.length >= 9
        ? 'con registros distribuidos a lo largo de la mayoría de las semanas'
        : weeks.length >= 5
            ? 'con actividad en varias semanas'
            : 'con actividad concentrada en pocas semanas';
    final consistencyEn = weeks.length >= 9
        ? 'with records across most weeks'
        : weeks.length >= 5
            ? 'with activity recorded across several weeks'
            : 'with records concentrated in a few weeks';
    final spanishSport = _sportEs(leading.key);
    final dominantEs = share >= .75
        ? 'Su disciplina predominante es ' + spanishSport + '.'
        : 'Combina varias disciplinas; la más frecuente es ' +
            spanishSport + '.';
    final dominantEn = share >= .75
        ? 'The main discipline is ' + leading.key + '.'
        : 'Several disciplines appear, most often ' + leading.key + '.';
    final averageEs = average.toStringAsFixed(1);
    final averageEn = average.toStringAsFixed(1);
    return PrivateActivityEvidence(
      sessions: count,
      activeDays: dates.length,
      activeWeeks: weeks.length,
      averageDaysPerWeek: average,
      primarySport: leading.key,
      primarySportShare: share,
      summaryEs: frequencyEs + ': registra actividad unos ' + averageEs +
          ' días por semana durante los últimos 90 días, ' +
          consistencyEs + '. ' + dominantEs +
          ' Este texto describe el archivo aportado y no certifica las actividades.',
      summaryEn: frequencyEn + ': activity is recorded on about ' +
          averageEn + ' days per week during the last 90 days, ' +
          consistencyEn + '. ' + dominantEn +
          ' This description reflects the provided file and does not certify activities.',
      importedAt: reference,
    );
  }

  static String _sport(String raw) {
    final s = raw.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (s.contains('run')) return 'Running';
    if (s.contains('ride') || s.contains('cycling') || s.contains('bike')) {
      return 'Cycling';
    }
    if (s.contains('swim')) return 'Swimming';
    if (s.contains('walk') || s.contains('hike')) return 'Walking / Hiking';
    if (s.contains('weight') || s.contains('strength')) return 'Strength';
    if (s.contains('yoga')) return 'Yoga';
    if (s.contains('workout') || s.contains('crossfit')) return 'Workout';
    return 'Other activity';
  }

  static String _sportEs(String sport) {
    const names = {
      'Running': 'running',
      'Cycling': 'ciclismo',
      'Swimming': 'natación',
      'Walking / Hiking': 'caminata o senderismo',
      'Strength': 'entrenamiento de fuerza',
      'Yoga': 'yoga',
      'Workout': 'entrenamiento general',
      'Other activity': 'actividad física variada',
    };
    return names[sport] ?? 'actividad física';
  }

  static DateTime? _date(String input) {
    final value = input.trim();
    final direct = DateTime.tryParse(value);
    if (direct != null) return direct;
    final parts = RegExp(
      r'^([A-Za-z]{3})\s+(\d{1,2}),\s+(\d{4}),?\s+(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (parts == null) return null;
    const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    final month = months.indexOf(parts.group(1)!.toLowerCase()) + 1;
    if (month == 0) return null;
    var hour = int.parse(parts.group(4)!);
    final suffix = parts.group(7)?.toUpperCase();
    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    final dayValue = int.parse(parts.group(2)!);
    final year = int.parse(parts.group(3)!);
    final candidate = DateTime(year, month, dayValue, hour,
        int.parse(parts.group(5)!), int.parse(parts.group(6)!));
    if (candidate.year != year || candidate.month != month ||
        candidate.day != dayValue) return null;
    return candidate;
  }

  static List<List<String>> _csv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (c == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((c == '\n' || c == '\r') && !quoted) {
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(field.toString());
        if (row.any((v) => v.trim().isNotEmpty)) rows.add(row);
        row = [];
        field = StringBuffer();
      } else {
        field.write(c);
      }
    }
    if (quoted) throw const FormatException('CSV con comillas incompletas.');
    row.add(field.toString());
    if (row.any((v) => v.trim().isNotEmpty)) rows.add(row);
    return rows;
  }
}

/// Store only the non-sensitive, derived owner-only result. Not the CSV.
String encodePrivateEvidence(PrivateActivityEvidence value) =>
    jsonEncode(value.toJson());
PrivateActivityEvidence decodePrivateEvidence(String value) =>
    PrivateActivityEvidence.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map));
