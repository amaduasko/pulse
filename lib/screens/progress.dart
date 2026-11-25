import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../stats.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final now = DateTime.now();
    final logs = store.logs;
    final week = lastSevenDays(logs, now);
    final maxMin = week.fold(0, (a, b) => a > b ? a : b);

    Widget tile(IconData icon, String value, String label) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: t.colorScheme.primary),
                const SizedBox(height: 10),
                Text(value, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
            Text('Progress', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(children: [
              tile(Icons.local_fire_department_outlined, '${currentStreak(logs, now)}', 'day streak'),
              const SizedBox(width: 10),
              tile(Icons.event_available_outlined, '${workoutsInLastSevenDays(logs, now)}', 'this week'),
              const SizedBox(width: 10),
              tile(Icons.schedule, '${totalMinutes(logs)}', 'total min'),
            ]),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Last 7 days', style: t.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Semantics(
                            label: '${_weekdays[now.subtract(Duration(days: 6 - i)).weekday - 1]}: ${week[i]} minutes',
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              if (week[i] > 0)
                                Text('${week[i]}', style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Container(
                                height: maxMin == 0 ? 4 : 4 + 96 * week[i] / maxMin,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: week[i] > 0 ? t.colorScheme.primary : t.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(_weekdays[now.subtract(Duration(days: 6 - i)).weekday - 1],
                                  style: t.textTheme.labelMedium?.copyWith(
                                    fontWeight: i == 6 ? FontWeight.w700 : null,
                                    color: i == 6 ? t.colorScheme.primary : t.colorScheme.onSurfaceVariant,
                                  )),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Text('History', style: t.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              const StateMessage(
                icon: Icons.insights,
                title: 'No workouts yet',
                text: 'Finish your first workout on the Today tab and it will show up here.',
              )
            else
              for (final l in logs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: t.colorScheme.primaryContainer,
                        child: Icon(Icons.check, color: t.colorScheme.onPrimaryContainer),
                      ),
                      title: Text(l.title),
                      subtitle: Text('${_date(l.date)} · ${l.minutes} min · ${l.exercisesDone}/${l.exercisesTotal} exercises'),
                    ),
                  ),
                ),
          ]),
        ),
      ),
    );
  }

  static String _date(DateTime d) {
    final l = d.toLocal();
    final m = l.minute.toString().padLeft(2, '0');
    return '${_weekdays[l.weekday - 1]} ${l.day} ${_months[l.month - 1]}, ${l.hour}:$m';
  }
}
