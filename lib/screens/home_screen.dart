import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/solver_state.dart';
import '../widgets/solver/feedback_row.dart';
import '../widgets/solver/recommendations_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solverControllerProvider);
    final controller = ref.read(solverControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final body = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _GridSection(state: state, controller: controller)),
                  const SizedBox(width: 24),
                  Expanded(child: _RecommendationsSection(state: state, controller: controller)),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GridSection(state: state, controller: controller),
                    const SizedBox(height: 24),
                    _RecommendationsSection(state: state, controller: controller),
                  ],
                ),
              );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Wordle Solver'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: body,
        );
      },
    );
  }
}

class _GridSection extends StatelessWidget {
  final SolverUiState state;
  final SolverController controller;

  const _GridSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? CupertinoSegmentedControl<int>(
                      children: const {5: Text('5'), 6: Text('6')},
                      groupValue: state.config.wordLength,
                      onValueChanged: (v) => controller.setWordLength(v),
                    )
                  : DropdownButton<int>(
                      value: state.config.wordLength,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 6, child: Text('6')),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.setWordLength(v);
                      },
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Prefix (optional)',
                ),
                onChanged: controller.setPrefix,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: state.config.dictionary,
                items: const [
                  DropdownMenuItem(value: 'english.json', child: Text('English')),
                  DropdownMenuItem(value: 'spanish.json', child: Text('Spanish')),
                ],
                onChanged: (v) {
                  if (v != null) controller.setDictionary(v);
                },
                decoration: const InputDecoration(labelText: 'Dictionary'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LayoutBuilder(builder: (context, c) {
                  return Column(
                    children: [
                      for (int r = 0; r < state.grid.length; r++) ...[
                        FeedbackRow(
                          tiles: state.grid[r],
                          onToggleFeedback: (i) => controller.toggleFeedback(i),
                          onLetterChanged: (i, v) => controller.setLetter(i, v),
                          maxWidth: c.maxWidth - 32, // inner padding margin
                        ),
                        if (r != state.grid.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Theme.of(context).platform == TargetPlatform.iOS
                      ? CupertinoButton.filled(
                          onPressed: state.isLoading ? null : controller.requestRecommendations,
                          child: state.isLoading
                              ? const CupertinoActivityIndicator()
                              : const Text('Recommend'),
                        )
                      : ElevatedButton.icon(
                          onPressed: state.isLoading ? null : controller.requestRecommendations,
                          icon: state.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.tips_and_updates),
                          label: const Text('Recommend'),
                        ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(state.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final SolverUiState state;
  final SolverController controller;

  const _RecommendationsSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RecommendationsPanel(
          response: state.lastResponse,
          onSelectWord: (word) {
            // Autofill current row with selected word
            for (int i = 0; i < state.config.wordLength && i < word.length; i++) {
              controller.setLetter(i, word[i]);
            }
          },
        ),
      ),
    );
  }
}


