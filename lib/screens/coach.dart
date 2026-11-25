import 'package:material_ui/material_ui.dart';

import '../main.dart';

const suggestions = [
  'What should I eat after a workout?',
  'How do I stay motivated?',
  'How many rest days do I need?',
  'Make my workout harder',
];

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final store = StoreScope.of(context);
    if (text.trim().isEmpty || store.chatLoading) return;
    _input.clear();
    final future = store.ask(text);
    _toBottom();
    await future;
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final chat = store.chat;

    return Scaffold(
      body: SafeArea(
        child: PageBody(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(children: [
                Text('Coach', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: t.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 16, color: t.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text('AI', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.onPrimaryContainer)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: chat.isEmpty
                  ? ListView(padding: const EdgeInsets.all(20), children: [
                      const StateMessage(
                        icon: Icons.chat_bubble_outline,
                        title: 'Ask your coach',
                        text: 'Training, food, recovery: answers use your goal and level. Any language works.',
                      ),
                      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                        for (final s in suggestions)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 44),
                              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _send(s),
                            child: Text(s),
                          ),
                      ]),
                    ])
                  : ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
                      for (final m in chat) _Bubble(text: m.content, mine: m.role == 'user'),
                      if (store.chatLoading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                            SizedBox(width: 10),
                            Text('Coach is thinking…'),
                          ]),
                        ),
                      if (store.chatError != null)
                        Card(
                          color: t.colorScheme.errorContainer,
                          child: ListTile(
                            leading: Icon(Icons.error_outline, color: t.colorScheme.onErrorContainer),
                            title: Text(store.chatError!, style: TextStyle(color: t.colorScheme.onErrorContainer)),
                            trailing: TextButton(onPressed: store.retryChat, child: const Text('Retry')),
                          ),
                        ),
                    ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    style: const TextStyle(fontSize: 16),
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(hintText: 'Ask about training or food', counterText: ''),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  iconSize: 24,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                  onPressed: store.chatLoading ? null : () => _send(_input.text),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine});
  final String text;
  final bool mine;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8 > 560 ? 560 : MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: mine ? c.primary : c.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(mine ? 20 : 6),
              bottomRight: Radius.circular(mine ? 6 : 20),
            ),
          ),
          child: SelectableText(text, style: TextStyle(fontSize: 16, height: 1.4, color: mine ? c.onPrimary : c.onSurface)),
        ),
      ),
    );
  }
}
