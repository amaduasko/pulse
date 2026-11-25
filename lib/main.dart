import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'screens/coach.dart';
import 'screens/onboarding.dart';
import 'screens/progress.dart';
import 'screens/settings.dart';
import 'screens/today.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(PulseApp(store: AppStore(prefs, CoachApi())));
}

const seed = Color(0xFF12B886);

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

/// Exposes the store to the widget tree.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);
  static AppStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: 'Pulse: AI fitness coach',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: store.themeMode,
          home: store.onboarded ? const HomeShell() : const OnboardingScreen(),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const destinations = [
    (Icons.fitness_center_outlined, Icons.fitness_center, 'Today'),
    (Icons.insights_outlined, Icons.insights, 'Progress'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Coach'),
    (Icons.tune_outlined, Icons.tune, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodayScreen(),
      const ProgressScreen(),
      const CoachScreen(),
      const SettingsScreen(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = IndexedStack(index: index, children: pages);
    void go(int i) => setState(() => index = i);

    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: go,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: PulseLogo(size: 40)),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: go,
        destinations: [
          for (final d in destinations) NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
        ],
      ),
    );
  }
}

class PulseLogo extends StatelessWidget {
  const PulseLogo({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(Icons.monitor_heart_outlined, color: c.onPrimary, size: size * 0.58),
    );
  }
}

/// Centers content with a readable max width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// A designed empty or error state.
class StateMessage extends StatelessWidget {
  const StateMessage({super.key, required this.icon, required this.title, required this.text, this.action});
  final IconData icon;
  final String title;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 36, backgroundColor: t.colorScheme.primaryContainer, child: Icon(icon, size: 34, color: t.colorScheme.onPrimaryContainer)),
        const SizedBox(height: 20),
        Text(title, style: t.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(text, style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ]),
    );
  }
}
