import 'package:material_ui/material_ui.dart';

import '../models.dart';

/// The four profile choices, shared by onboarding and settings.
class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key, required this.value, required this.onChanged});
  final Profile value;
  final ValueChanged<Profile> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget section<T>(String label, Map<T, String> options, T selected, Profile Function(T) apply) {
      final t = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t.textTheme.titleSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in options.entries)
              ChoiceChip(
                label: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(e.value, style: const TextStyle(fontSize: 15))),
                selected: e.key == selected,
                onSelected: (_) => onChanged(apply(e.key)),
              ),
          ]),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      section('Your goal', goalLabels, value.goal, (g) => value.copyWith(goal: g)),
      section('Your level', levelLabels, value.level, (l) => value.copyWith(level: l)),
      section('Equipment', equipmentLabels, value.equipment, (e) => value.copyWith(equipment: e)),
      section('Session length', {for (final m in const [15, 30, 45, 60]) m: '$m min'}, value.minutes,
          (m) => value.copyWith(minutes: m)),
    ]);
  }
}
