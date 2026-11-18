import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/private_activity_evidence.dart';

void main() {
  final reference = DateTime(2026, 11, 16, 18);

  test('realistic weekly pattern produces factual private summary', () {
    final rows = <String>['Activity ID,Activity Date,Activity Type'];
    var id = 1;
    for (var week = 0; week < 13; week++) {
      for (final weekday in [0, 2, 4]) {
        final date = DateTime(2026, 8, 19)
            .add(Duration(days: week * 7 + weekday));
        if (date.isAfter(reference)) continue;
        rows.add(id.toString() + ',' +
            date.toIso8601String() + ',Run');
        id++;
      }
    }
    final summary = PrivateActivityEvidenceAnalyzer.analyze(
      rows.join('\n'), today: reference);
    expect(summary.sessions, greaterThanOrEqualTo(35));
    expect(summary.averageDaysPerWeek, greaterThan(2.7));
    expect(summary.primarySport, 'Running');
    expect(summary.primarySportShare, 1);
    expect(summary.summaryEs, contains('últimos 90 días'));
    expect(summary.summaryEs, contains('running'));
    expect(summary.summaryEs, contains('no certifica'));
  });

  test('quoted Strava dates, escaped CSV values and duplicate ID', () {
    const csv = 'Activity ID,Activity Date,Activity Name,Activity Type\r\n'
        '123,"Oct 15, 2026, 7:02:03 AM","Run, happy day",Run\r\n'
        '123,"Oct 15, 2026, 7:02:03 AM","Run, happy day",Run\r\n'
        '124,"Nov 02, 2026, 7:02:03 PM","Trail ""long""",TrailRun\r\n'
        '125,"Nov 03, 2026, 7:02:03 AM","Spin",Ride\r\n';
    final result = PrivateActivityEvidenceAnalyzer.analyze(
      csv, today: reference);
    expect(result.sessions, 3);
    expect(result.activeDays, 3);
    expect(result.primarySport, 'Running');
  });

  test('no fabricated inference when last 90 days have no entries', () {
    const csv = 'Activity Date,Activity Type\n'
        '"Oct 15, 2022, 8:02:03 AM",Run\n';
    expect(
      () => PrivateActivityEvidenceAnalyzer.analyze(
        csv, today: reference),
      throwsFormatException,
    );
  });

  test('rejects malformed or non-Strava CSV', () {
    expect(
      () => PrivateActivityEvidenceAnalyzer.analyze(
        'Name,Date\nX,2026-11-15', today: reference),
      throwsFormatException,
    );
    expect(
      () => PrivateActivityEvidenceAnalyzer.analyze(
        'Activity Date,Activity Type\n"unterminated,Run', today: reference),
      throwsFormatException,
    );
  });

  test('only derived summary is serialised for local owner storage', () {
    final result = PrivateActivityEvidenceAnalyzer.analyze(
      'Activity ID,Activity Date,Activity Type\n'
      '1,2026-11-15T07:01:00,Run', today: reference);
    final encoded = encodePrivateEvidence(result);
    expect(encoded, isNot(contains('2026-11-15T07:01:00')));
    expect(encoded, isNot(contains('Activity ID')));
    final decoded = decodePrivateEvidence(encoded);
    expect(decoded.sessions, 1);
    expect(decoded.summaryEs, result.summaryEs);
  });
}
