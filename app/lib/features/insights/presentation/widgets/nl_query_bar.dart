import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/insights_providers.dart';

/// "How much did I spend on food last month vs my salary?" — free-form
/// question box that hits POST /api/query.
class NlQueryBar extends ConsumerStatefulWidget {
  const NlQueryBar({super.key});

  @override
  ConsumerState<NlQueryBar> createState() => _NlQueryBarState();
}

class _NlQueryBarState extends ConsumerState<NlQueryBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(nlQueryControllerProvider.notifier).ask(question);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(nlQueryControllerProvider).isLoading;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Ask about your spending…',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Ask',
                onPressed: _submit,
              ),
          ],
        ),
      ),
    );
  }
}
