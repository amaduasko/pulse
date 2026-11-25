import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulse/api.dart';
import 'package:pulse/main.dart';
import 'package:pulse/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const aiPlan = {
  'plan': {
    'title': 'Lean Burn',
    'summary': 'A fast full-body session.',
    'exercises': [
      {'name': 'Air squats', 'sets': 2, 'reps': '15', 'restSeconds': 30, 'tip': 'Sit back.'},
      {'name': 'Mountain climbers', 'sets': 2, 'reps': '30 s', 'restSeconds': 30, 'tip': 'Hips low.'},
      {'name': 'Push-ups', 'sets': 2, 'reps': '10', 'restSeconds': 30, 'tip': 'Elbows 45°.'},
    ],
  },
};

Future<AppStore> pump(WidgetTester tester, MockClient client) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = AppStore(prefs, CoachApi(client: client, endpoint: Uri.parse('https://x.test/api/coach')));
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PulseApp(store: store));
  return store;
}

void main() {
  testWidgets('onboarding → AI plan → log a workout', (tester) async {
    late Map<String, dynamic> sent;
    final store = await pump(tester, MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(aiPlan), 200);
    }));

    expect(find.text('Your AI fitness coach'), findsOneWidget);
    await tester.tap(find.text('Lose weight'));
    await tester.ensureVisible(find.text('Dumbbells'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbells'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Create my plan'), 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Create my plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create my plan'));
    await tester.pumpAndSettle();

    expect(sent['mode'], 'plan');
    expect(sent['profile'], {'goal': 'lose_weight', 'level': 'beginner', 'equipment': 'dumbbells', 'minutes': 30});
    expect(find.text('Lean Burn'), findsOneWidget);
    expect(find.text('Made by your AI coach'), findsOneWidget);

    await tester.ensureVisible(find.text('Air squats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Air squats'));
    await tester.pump();
    expect(find.textContaining('Rest 30s'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();

    await tester.ensureVisible(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    expect(store.logs.length, 1);
    expect(find.textContaining('Workout saved'), findsOneWidget);
  });

  testWidgets('falls back to a built-in plan when the coach is down', (tester) async {
    await pump(tester, MockClient((_) async => http.Response('{"error":"The coach is unavailable right now"}', 502)));
    await tester.scrollUntilVisible(find.text('Create my plan'), 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Create my plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create my plan'));
    await tester.pumpAndSettle();
    expect(find.text('Built-in plan'), findsOneWidget);
    expect(find.textContaining('here is a built-in plan'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
