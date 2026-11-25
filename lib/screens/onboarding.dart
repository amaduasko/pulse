import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models.dart';
import 'profile_form.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Profile profile = const Profile();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final store = StoreScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          maxWidth: 560,
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 32), children: [
            const Align(alignment: Alignment.centerLeft, child: PulseLogo(size: 56)),
            const SizedBox(height: 24),
            Text('Your AI fitness coach', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Pick four things and Pulse builds today\'s workout for you.',
                style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            ProfileForm(value: profile, onChanged: (p) => setState(() => profile = p)),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create my plan'),
              onPressed: () async {
                await store.setProfile(profile);
                store.newPlan();
              },
            ),
            const SizedBox(height: 12),
            Text('Your data stays on this device.',
                textAlign: TextAlign.center, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
