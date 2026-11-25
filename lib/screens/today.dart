import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models.dart';
import '../store.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Timer? _timer;
  int restLeft = 0;
  String restFor = '';

  void _startRest(Exercise ex) {
    _timer?.cancel();
    if (ex.restSeconds <= 0) return;
    setState(() {
      restLeft = ex.restSeconds;
      restFor = ex.name;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => restLeft--);
      if (restLeft <= 0) t.cancel();
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() => restLeft = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _finish(AppStore store) async {
    _skipRest();
    final log = await store.finishWorkout();
    if (!mounted || log == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Text('Workout saved: ${log.exercisesDone}/${log.exercisesTotal} exercises, ${log.minutes} min. Nice work!'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final plan = store.plan;
    final profile = store.profile!;

    Widget content;
    if (store.planStatus == PlanStatus.loading) {
      content = const _PlanLoading();
    } else if (plan == null) {
      content = StateMessage(
        icon: Icons.fitness_center,
        title: 'No plan yet',
        text: 'Your coach will build a ${profile.minutes}-minute workout for your goal.',
        action: FilledButton.icon(icon: const Icon(Icons.auto_awesome), label: const Text('Create my plan'), onPressed: store.newPlan),
      );
    } else {
      final done = store.exercisesDone;
      final total = plan.exercises.length;
      content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (store.planNotice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: t.colorScheme.tertiaryContainer,
              child: ListTile(
                leading: Icon(Icons.wifi_off, color: t.colorScheme.onTertiaryContainer),
                title: Text(store.planNotice!, style: TextStyle(color: t.colorScheme.onTertiaryContainer)),
                trailing: TextButton(onPressed: store.newPlan, child: const Text('Retry')),
              ),
            ),
          ),
        Card(
          color: t.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(plan.fromAi ? Icons.auto_awesome : Icons.bookmark_outline, size: 18, color: t.colorScheme.onPrimaryContainer),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(plan.fromAi ? 'Made by your AI coach' : 'Built-in plan',
                      style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.onPrimaryContainer)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(plan.title, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: t.colorScheme.onPrimaryContainer)),
              if (plan.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(plan.summary, style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onPrimaryContainer)),
              ],
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 10),
              ),
              const SizedBox(height: 8),
              Text('$done of $total exercises done', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.onPrimaryContainer)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Tap an exercise each time you finish a set.',
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
        for (var i = 0; i < plan.exercises.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExerciseCard(
              exercise: plan.exercises[i],
              setsDone: store.setsDone[i] ?? 0,
              onTap: () async {
                final ex = plan.exercises[i];
                final before = store.setsDone[i] ?? 0;
                await store.tapExercise(i);
                if (before < ex.sets) {
                  if (before + 1 < ex.sets || store.exercisesDone < total) {
                    _startRest(ex);
                  } else {
                    _skipRest();
                  }
                } else {
                  _skipRest();
                }
              },
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Finish workout'),
          onPressed: store.workoutStarted ? () => _finish(store) : null,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('New plan'),
          onPressed: () async {
            if (store.workoutStarted) {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Start a new plan?'),
                  content: const Text('Progress on this workout will be lost. Finish it first to save it.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('New plan')),
                  ],
                ),
              );
              if (ok != true) return;
            }
            _skipRest();
            store.newPlan();
          },
        ),
      ]);
    }

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 120), children: [
            Text(_greeting(), style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            Text('Today', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${goalLabels[profile.goal]} · ${levelLabels[profile.level]} · ${equipmentLabels[profile.equipment]} · ${profile.minutes} min',
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            content,
          ]),
        ),
      ),
      bottomSheet: restLeft > 0 ? _RestBar(seconds: restLeft, exercise: restFor, onSkip: _skipRest) : null,
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.setsDone, required this.onTap});
  final Exercise exercise;
  final int setsDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final complete = setsDone >= exercise.sets;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: complete ? t.colorScheme.primary : t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: complete
                    ? Icon(Icons.check, color: t.colorScheme.onPrimary)
                    : Text('$setsDone/${exercise.sets}', style: t.textTheme.labelLarge),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(exercise.name,
                    style: t.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: complete ? TextDecoration.lineThrough : null,
                    )),
                const SizedBox(height: 2),
                Text('${exercise.sets} × ${exercise.reps}${exercise.restSeconds > 0 ? ' · rest ${exercise.restSeconds} s' : ''}',
                    style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                if (exercise.tip.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: t.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(exercise.tip, style: t.textTheme.bodyMedium)),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({required this.seconds, required this.exercise, required this.onSkip});
  final int seconds;
  final String exercise;
  final VoidCallback onSkip;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.inverseSurface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(children: [
            Icon(Icons.timer_outlined, color: t.colorScheme.onInverseSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Rest ${seconds}s · $exercise',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.onInverseSurface)),
            ),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(foregroundColor: t.colorScheme.inversePrimary, minimumSize: const Size(64, 48)),
              child: const Text('Skip'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlanLoading extends StatelessWidget {
  const _PlanLoading();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget bar(double h) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: t.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(width: 12),
        Expanded(child: Text('Your coach is building today\'s workout…', style: t.textTheme.titleMedium)),
      ]),
      const SizedBox(height: 16),
      bar(150),
      for (var i = 0; i < 4; i++) bar(84),
    ]);
  }
}
