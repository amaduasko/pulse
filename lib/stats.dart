import 'models.dart';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Consecutive days with at least one workout, ending today or yesterday.
int currentStreak(List<WorkoutLog> logs, DateTime now) {
  final days = logs.map((l) => dayOf(l.date.toLocal())).toSet();
  var day = dayOf(now);
  if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Minutes trained on each of the last 7 days, oldest first (index 6 is today).
List<int> lastSevenDays(List<WorkoutLog> logs, DateTime now) {
  final today = dayOf(now);
  final out = List<int>.filled(7, 0);
  for (final l in logs) {
    final diff = today.difference(dayOf(l.date.toLocal())).inDays;
    if (diff >= 0 && diff < 7) out[6 - diff] += l.minutes;
  }
  return out;
}

int workoutsInLastSevenDays(List<WorkoutLog> logs, DateTime now) {
  final today = dayOf(now);
  return logs.where((l) {
    final diff = today.difference(dayOf(l.date.toLocal())).inDays;
    return diff >= 0 && diff < 7;
  }).length;
}

int totalMinutes(List<WorkoutLog> logs) => logs.fold(0, (s, l) => s + l.minutes);
