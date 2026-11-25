import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/fallback_plan.dart';
import 'package:pulse/models.dart';
import 'package:pulse/stats.dart';

WorkoutLog log(DateTime d, [int min = 30]) =>
    WorkoutLog(date: d, title: 'W', minutes: min, exercisesDone: 5, exercisesTotal: 6);

void main() {
  final now = DateTime(2026, 11, 25, 18);

  group('streak', () {
    test('counts consecutive days ending today', () {
      final logs = [log(DateTime(2026, 11, 25, 8)), log(DateTime(2026, 11, 24)), log(DateTime(2026, 11, 23))];
      expect(currentStreak(logs, now), 3);
    });
    test('still counts when the last workout was yesterday', () {
      expect(currentStreak([log(DateTime(2026, 11, 24)), log(DateTime(2026, 11, 23))], now), 2);
    });
    test('breaks on a missed day and ignores duplicates', () {
      final logs = [log(DateTime(2026, 11, 25, 7)), log(DateTime(2026, 11, 25, 19)), log(DateTime(2026, 11, 23))];
      expect(currentStreak(logs, now), 1);
    });
    test('is 0 with no recent workout', () {
      expect(currentStreak([log(DateTime(2026, 11, 20))], now), 0);
      expect(currentStreak([], now), 0);
    });
    test('crosses month boundaries', () {
      final d = DateTime(2026, 12, 1, 9);
      expect(currentStreak([log(DateTime(2026, 12, 1)), log(DateTime(2026, 11, 30)), log(DateTime(2026, 11, 29))], d), 3);
    });
  });

  test('last seven days sums minutes per day, today last', () {
    final logs = [log(DateTime(2026, 11, 25), 20), log(DateTime(2026, 11, 25), 10), log(DateTime(2026, 11, 19), 40), log(DateTime(2026, 11, 18), 99)];
    expect(lastSevenDays(logs, now), [40, 0, 0, 0, 0, 0, 30]);
    expect(workoutsInLastSevenDays(logs, now), 3);
    expect(totalMinutes(logs), 169);
  });

  group('plan parsing', () {
    test('clamps and cleans AI output', () {
      final p = Plan.fromJson({
        'title': '  ',
        'exercises': [
          {'name': 'Squats', 'sets': 99, 'reps': 12, 'restSeconds': '30'},
          {'name': '', 'sets': 3},
          {'name': 'Push-ups', 'sets': '3', 'reps': ''},
          'junk',
          {'name': 'Plank', 'restSeconds': -5},
        ],
      }, fromAi: true);
      expect(p.title, "Today's workout");
      expect(p.exercises.map((e) => e.name), ['Squats', 'Push-ups', 'Plank']);
      expect(p.exercises[0].sets, 10);
      expect(p.exercises[0].reps, '12');
      expect(p.exercises[0].restSeconds, 30);
      expect(p.exercises[1].reps, '10');
      expect(p.exercises[2].restSeconds, 0);
      expect(p.fromAi, isTrue);
    });
    test('rejects a plan with fewer than 3 exercises', () {
      expect(() => Plan.fromJson({'exercises': [{'name': 'A'}, {'name': 'B'}]}), throwsFormatException);
    });
    test('round-trips through storage', () {
      final p = fallbackPlan(const Profile(equipment: Equipment.gym), now: now);
      final back = Plan.fromJson(p.toJson());
      expect(back.exercises.length, p.exercises.length);
      expect(back.fromAi, isFalse);
      expect(back.createdAt, now);
    });
  });

  test('fallback plan fits equipment and level', () {
    for (final e in Equipment.values) {
      for (final l in Level.values) {
        final p = fallbackPlan(Profile(equipment: e, level: l));
        expect(p.exercises.length, greaterThanOrEqualTo(5));
        expect(p.fromAi, isFalse);
      }
    }
    expect(fallbackPlan(const Profile(level: Level.advanced)).exercises[1].sets, 4);
    expect(fallbackPlan(const Profile(level: Level.beginner)).exercises[1].sets, 2);
  });

  test('profile parsing falls back on bad data', () {
    final p = Profile.fromJson({'goal': 'fly', 'level': 'advanced', 'minutes': 500});
    expect(p.goal, Goal.stayActive);
    expect(p.level, Level.advanced);
    expect(p.minutes, 90);
    expect(p.toApi()['goal'], 'stay_active');
  });
}
