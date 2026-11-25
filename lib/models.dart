enum Goal { loseWeight, buildMuscle, stayActive, endurance }

enum Level { beginner, intermediate, advanced }

enum Equipment { none, dumbbells, gym }

const goalLabels = {
  Goal.loseWeight: 'Lose weight',
  Goal.buildMuscle: 'Build muscle',
  Goal.stayActive: 'Stay active',
  Goal.endurance: 'Endurance',
};
const goalApi = {
  Goal.loseWeight: 'lose_weight',
  Goal.buildMuscle: 'build_muscle',
  Goal.stayActive: 'stay_active',
  Goal.endurance: 'endurance',
};
const levelLabels = {
  Level.beginner: 'Beginner',
  Level.intermediate: 'Intermediate',
  Level.advanced: 'Advanced',
};
const equipmentLabels = {
  Equipment.none: 'No equipment',
  Equipment.dumbbells: 'Dumbbells',
  Equipment.gym: 'Full gym',
};

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class Profile {
  final Goal goal;
  final Level level;
  final Equipment equipment;
  final int minutes;

  const Profile({
    this.goal = Goal.stayActive,
    this.level = Level.beginner,
    this.equipment = Equipment.none,
    this.minutes = 30,
  });

  Profile copyWith({Goal? goal, Level? level, Equipment? equipment, int? minutes}) => Profile(
        goal: goal ?? this.goal,
        level: level ?? this.level,
        equipment: equipment ?? this.equipment,
        minutes: minutes ?? this.minutes,
      );

  Map<String, Object> toJson() =>
      {'goal': goal.name, 'level': level.name, 'equipment': equipment.name, 'minutes': minutes};

  Map<String, Object> toApi() => {
        'goal': goalApi[goal]!,
        'level': level.name,
        'equipment': equipment.name,
        'minutes': minutes,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        goal: _enumByName(Goal.values, j['goal'], Goal.stayActive),
        level: _enumByName(Level.values, j['level'], Level.beginner),
        equipment: _enumByName(Equipment.values, j['equipment'], Equipment.none),
        minutes: ((j['minutes'] as num?)?.toInt() ?? 30).clamp(10, 90),
      );
}

class Exercise {
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final String tip;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.tip = '',
  });

  Map<String, Object> toJson() =>
      {'name': name, 'sets': sets, 'reps': reps, 'restSeconds': restSeconds, 'tip': tip};

  /// Returns null when the entry has no usable name.
  static Exercise? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = (raw['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    int toInt(Object? v, int d) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
    final reps = (raw['reps'] ?? '').toString().trim();
    return Exercise(
      name: name.length > 60 ? name.substring(0, 60) : name,
      sets: toInt(raw['sets'], 3).clamp(1, 10),
      reps: reps.isEmpty ? '10' : reps,
      restSeconds: toInt(raw['restSeconds'], 45).clamp(0, 300),
      tip: (raw['tip'] ?? '').toString().trim(),
    );
  }
}

class Plan {
  final String title;
  final String summary;
  final List<Exercise> exercises;
  final bool fromAi;
  final DateTime createdAt;

  const Plan({
    required this.title,
    required this.summary,
    required this.exercises,
    required this.fromAi,
    required this.createdAt,
  });

  Map<String, Object> toJson() => {
        'title': title,
        'summary': summary,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'fromAi': fromAi,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Parses a plan from the API or storage. Throws [FormatException] when unusable.
  factory Plan.fromJson(Map<String, dynamic> j, {bool? fromAi, DateTime? now}) {
    final list = j['exercises'];
    final exercises = (list is List ? list : const [])
        .map(Exercise.tryParse)
        .whereType<Exercise>()
        .take(8)
        .toList();
    if (exercises.length < 3) throw const FormatException('Plan has too few exercises');
    final title = (j['title'] ?? '').toString().trim();
    return Plan(
      title: title.isEmpty ? "Today's workout" : title,
      summary: (j['summary'] ?? '').toString().trim(),
      exercises: exercises,
      fromAi: fromAi ?? (j['fromAi'] == true),
      createdAt: DateTime.tryParse('${j['createdAt']}') ?? now ?? DateTime.now(),
    );
  }
}

class WorkoutLog {
  final DateTime date;
  final String title;
  final int minutes;
  final int exercisesDone;
  final int exercisesTotal;

  const WorkoutLog({
    required this.date,
    required this.title,
    required this.minutes,
    required this.exercisesDone,
    required this.exercisesTotal,
  });

  Map<String, Object> toJson() => {
        'date': date.toIso8601String(),
        'title': title,
        'minutes': minutes,
        'exercisesDone': exercisesDone,
        'exercisesTotal': exercisesTotal,
      };

  static WorkoutLog? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final date = DateTime.tryParse('${raw['date']}');
    if (date == null) return null;
    return WorkoutLog(
      date: date,
      title: '${raw['title'] ?? 'Workout'}',
      minutes: (raw['minutes'] as num?)?.toInt() ?? 0,
      exercisesDone: (raw['exercisesDone'] as num?)?.toInt() ?? 0,
      exercisesTotal: (raw['exercisesTotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  const ChatMessage(this.role, this.content);
  Map<String, String> toJson() => {'role': role, 'content': content};
}
