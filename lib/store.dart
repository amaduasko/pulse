import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'fallback_plan.dart';
import 'models.dart';

enum PlanStatus { idle, loading, ready }

/// App state, kept on the device.
class AppStore extends ChangeNotifier {
  AppStore(this._prefs, this.api) {
    _load();
  }

  final SharedPreferences _prefs;
  final CoachApi api;

  Profile? profile;
  Plan? plan;
  PlanStatus planStatus = PlanStatus.idle;
  String? planNotice; // shown when we fell back to the built-in plan
  Map<int, int> setsDone = {}; // exercise index -> sets completed
  DateTime? workoutStartedAt;
  List<WorkoutLog> logs = [];
  ThemeMode themeMode = ThemeMode.system;
  final List<ChatMessage> chat = [];
  bool chatLoading = false;
  String? chatError;

  bool get onboarded => profile != null;

  void _load() {
    Map<String, dynamic>? read(String key) {
      final s = _prefs.getString(key);
      if (s == null) return null;
      try {
        final v = jsonDecode(s);
        return v is Map<String, dynamic> ? v : null;
      } catch (_) {
        return null;
      }
    }

    final p = read('profile');
    if (p != null) profile = Profile.fromJson(p);
    final pl = read('plan');
    if (pl != null) {
      try {
        plan = Plan.fromJson(pl);
        planStatus = PlanStatus.ready;
      } on FormatException {
        plan = null;
      }
    }
    final progress = read('progress');
    if (progress != null) {
      setsDone = {
        for (final e in progress.entries)
          if (int.tryParse(e.key) != null && e.value is num) int.parse(e.key): (e.value as num).toInt()
      };
    }
    try {
      final l = jsonDecode(_prefs.getString('logs') ?? '[]');
      if (l is List) logs = l.map(WorkoutLog.tryParse).whereType<WorkoutLog>().toList();
    } catch (_) {}
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString('theme'),
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> _savePlan() async {
    if (plan == null) {
      await _prefs.remove('plan');
    } else {
      await _prefs.setString('plan', jsonEncode(plan!.toJson()));
    }
    await _prefs.setString('progress', jsonEncode(setsDone.map((k, v) => MapEntry('$k', v))));
  }

  Future<void> setProfile(Profile p) async {
    profile = p;
    await _prefs.setString('profile', jsonEncode(p.toJson()));
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    await _prefs.setString('theme', m.name);
    notifyListeners();
  }

  Future<void> newPlan() async {
    final p = profile;
    if (p == null || planStatus == PlanStatus.loading) return;
    planStatus = PlanStatus.loading;
    planNotice = null;
    notifyListeners();
    Plan next;
    try {
      next = await api.plan(p);
    } on CoachException {
      next = fallbackPlan(p);
      planNotice = 'Your AI coach is offline right now, so here is a built-in plan.';
    }
    plan = next;
    setsDone = {};
    workoutStartedAt = null;
    planStatus = PlanStatus.ready;
    await _savePlan();
    notifyListeners();
  }

  /// Marks one more set of exercise [i] done; a full exercise resets to 0.
  Future<void> tapExercise(int i) async {
    final ex = plan?.exercises[i];
    if (ex == null) return;
    workoutStartedAt ??= DateTime.now();
    final done = setsDone[i] ?? 0;
    setsDone[i] = done >= ex.sets ? 0 : done + 1;
    await _savePlan();
    notifyListeners();
  }

  int get exercisesDone {
    final p = plan;
    if (p == null) return 0;
    var n = 0;
    for (var i = 0; i < p.exercises.length; i++) {
      if ((setsDone[i] ?? 0) >= p.exercises[i].sets) n++;
    }
    return n;
  }

  bool get workoutStarted => setsDone.values.any((v) => v > 0);

  Future<WorkoutLog?> finishWorkout() async {
    final p = plan;
    if (p == null || !workoutStarted) return null;
    final started = workoutStartedAt;
    final elapsed = started == null ? 0 : DateTime.now().difference(started).inMinutes;
    final minutes = elapsed >= 5 ? elapsed : (profile?.minutes ?? 30);
    final log = WorkoutLog(
      date: DateTime.now(),
      title: p.title,
      minutes: minutes.clamp(1, 240),
      exercisesDone: exercisesDone,
      exercisesTotal: p.exercises.length,
    );
    logs = [log, ...logs];
    await _prefs.setString('logs', jsonEncode(logs.map((l) => l.toJson()).toList()));
    setsDone = {};
    workoutStartedAt = null;
    await _savePlan();
    notifyListeners();
    return log;
  }

  Future<void> ask(String text) async {
    final q = text.trim();
    final p = profile;
    if (q.isEmpty || p == null || chatLoading) return;
    chat.add(ChatMessage('user', q));
    await _reply(p);
  }

  Future<void> retryChat() async {
    final p = profile;
    if (p == null || chatLoading || chat.isEmpty || chat.last.role != 'user') return;
    await _reply(p);
  }

  Future<void> _reply(Profile p) async {
    chatLoading = true;
    chatError = null;
    notifyListeners();
    try {
      chat.add(ChatMessage('assistant', await api.chat(p, chat)));
    } on CoachException catch (e) {
      chatError = e.message;
    }
    chatLoading = false;
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _prefs.clear();
    profile = null;
    plan = null;
    planStatus = PlanStatus.idle;
    planNotice = null;
    setsDone = {};
    workoutStartedAt = null;
    logs = [];
    chat.clear();
    chatError = null;
    themeMode = ThemeMode.system;
    notifyListeners();
  }
}
