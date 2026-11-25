import 'models.dart';

/// A safe built-in plan used when the AI coach can't be reached.
Plan fallbackPlan(Profile p, {DateTime? now}) {
  final hard = p.level == Level.advanced;
  final mid = p.level == Level.intermediate;
  final sets = hard ? 4 : (mid ? 3 : 2);
  final rest = hard ? 45 : 60;
  String reps(int base) => '${base + (hard ? 6 : mid ? 3 : 0)}';

  final List<Exercise> list = switch (p.equipment) {
    Equipment.none => [
        Exercise(name: 'Jumping jacks', sets: 1, reps: '60 s', restSeconds: 30, tip: 'Land softly on the balls of your feet.'),
        Exercise(name: 'Bodyweight squats', sets: sets, reps: reps(12), restSeconds: rest, tip: 'Knees track over your toes, chest up.'),
        Exercise(name: 'Push-ups', sets: sets, reps: reps(8), restSeconds: rest, tip: 'Keep a straight line from head to heels.'),
        Exercise(name: 'Reverse lunges', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Step back far enough that the front shin stays vertical.'),
        Exercise(name: 'Glute bridges', sets: sets, reps: reps(12), restSeconds: rest, tip: 'Squeeze at the top for one second.'),
        Exercise(name: 'Plank', sets: sets, reps: hard ? '60 s' : '30 s', restSeconds: rest, tip: 'Brace your core and do not let the hips sag.'),
      ],
    Equipment.dumbbells => [
        Exercise(name: 'Goblet squats', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Hold the dumbbell at your chest, elbows inside the knees.'),
        Exercise(name: 'Dumbbell rows', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Pull the elbow toward your hip.'),
        Exercise(name: 'Dumbbell floor press', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Lower slowly until your upper arms touch the floor.'),
        Exercise(name: 'Romanian deadlifts', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Hinge at the hips with a flat back.'),
        Exercise(name: 'Shoulder press', sets: sets, reps: reps(8), restSeconds: rest, tip: 'Ribs down, do not arch your lower back.'),
        Exercise(name: 'Dead bug', sets: sets, reps: reps(8), restSeconds: rest, tip: 'Press your lower back into the floor.'),
      ],
    Equipment.gym => [
        Exercise(name: 'Rowing machine warm-up', sets: 1, reps: '5 min', restSeconds: 30, tip: 'Legs, then body, then arms.'),
        Exercise(name: 'Back squats', sets: sets, reps: reps(8), restSeconds: rest + 30, tip: 'Brace before each rep.'),
        Exercise(name: 'Lat pulldown', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Pull the bar to your upper chest.'),
        Exercise(name: 'Bench press', sets: sets, reps: reps(8), restSeconds: rest + 30, tip: 'Shoulder blades pinched together.'),
        Exercise(name: 'Leg curls', sets: sets, reps: reps(10), restSeconds: rest, tip: 'Control the way back up.'),
        Exercise(name: 'Cable crunches', sets: sets, reps: reps(12), restSeconds: rest, tip: 'Curl your spine, not your hips.'),
      ],
  };

  return Plan(
    title: '${goalLabels[p.goal]} basics',
    summary: 'A built-in ${p.minutes}-minute session for ${levelLabels[p.level]!.toLowerCase()}s.',
    exercises: list,
    fromAi: false,
    createdAt: now ?? DateTime.now(),
  );
}
