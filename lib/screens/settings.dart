import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models.dart';
import 'profile_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final profile = store.profile ?? const Profile();

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
            Text('Settings', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your profile', style: t.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Your next plan and the coach\'s answers use these.',
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  ProfileForm(value: profile, onChanged: store.setProfile),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Theme', style: t.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                      ],
                      selected: {store.themeMode},
                      onSelectionChanged: (s) => store.setTheme(s.first),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                minTileHeight: 72,
                leading: Icon(Icons.delete_outline, color: t.colorScheme.error),
                title: Text('Clear all data', style: TextStyle(color: t.colorScheme.error)),
                subtitle: const Text('Deletes your profile, plan and history from this device.'),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Clear all data?'),
                      content: const Text('Your profile, plan and workout history will be deleted. This can\'t be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: t.colorScheme.error, foregroundColor: t.colorScheme.onError),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await store.clearAll();
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Pulse · AI fitness coach\nBuilt with Flutter. Your data stays on this device.',
                textAlign: TextAlign.center, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
