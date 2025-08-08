import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/solver_state.dart';
import '../widgets/solver/feedback_row.dart';
import '../widgets/solver/recommendations_panel.dart';
import '../widgets/common/aurora.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solverControllerProvider);
    final controller = ref.read(solverControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopControls(state: state, controller: controller),
              const SizedBox(height: 16),
              _GridSection(state: state, controller: controller),
              const SizedBox(height: 24),
              _RecommendationsSection(
                state: state,
                controller: controller,
              ),
            ],
          ),
        );

        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.25),
              radius: 1.2,
              colors: [Color(0xFF1F2540), Color(0xFF0A0B0D)],
              stops: [0.0, 1.0],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Wordle Solver',
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  )),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopControls extends StatelessWidget {
  final SolverUiState state;
  final SolverController controller;

  const _TopControls({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Length: ${state.config.wordLength}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.white)),
                    Slider(
                      min: 3,
                      max: 20,
                      divisions: 17,
                      value: state.config.wordLength.toDouble(),
                      onChanged: (v) => controller.setWordLength(v.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Prefix (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: controller.setPrefix,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: state.config.dictionary,
                  items: const [
                    DropdownMenuItem(
                      value: 'english.json',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'spanish.json',
                      child: Text('Spanish'),
                    ),
                  ],
                  dropdownColor: const Color(0xFF1A1B1F),
                  onChanged: (v) {
                    if (v != null) controller.setDictionary(v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Dictionary',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final hasPrefix = (state.config.prefix ?? '').isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPrefix)
          AuroraCard(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    return Column(
                      children: [
                        for (int r = 0; r < state.grid.length; r++) ...[
                          _FocusableFeedbackRow(
                            tiles: state.grid[r],
                            onToggleFeedback: (i) => controller.toggleFeedback(i),
                            onLetterChanged: (i, v) => controller.setLetter(i, v),
                            maxWidth: c.maxWidth - 32, // inner padding margin
                          ),
                          if (r != state.grid.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Theme.of(context).platform == TargetPlatform.iOS
                      ? CupertinoButton.filled(
                          onPressed: state.isLoading
                              ? null
                              : controller.requestRecommendations,
                          child: state.isLoading
                              ? const CupertinoActivityIndicator()
                              : const Text('Recommend'),
                        )
                      : ElevatedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : controller.requestRecommendations,
                          icon: state.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.tips_and_updates),
                          label: const Text('Recommend'),
                        ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final SolverUiState state;
  final SolverController controller;

  const _RecommendationsSection({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RecommendationsPanel(
          response: state.lastResponse,
          onSelectWord: (word) {
            // Autofill current row with selected word
            for (
              int i = 0;
              i < state.config.wordLength && i < word.length;
              i++
            ) {
              controller.setLetter(i, word[i]);
            }
          },
        ),
      ),
    );
  }
}

class _FocusableFeedbackRow extends StatefulWidget {
  final List<SolverTile> tiles;
  final void Function(int index) onToggleFeedback;
  final void Function(int index, String letter) onLetterChanged;
  final double maxWidth;

  const _FocusableFeedbackRow({
    required this.tiles,
    required this.onToggleFeedback,
    required this.onLetterChanged,
    required this.maxWidth,
  });

  @override
  State<_FocusableFeedbackRow> createState() => _FocusableFeedbackRowState();
}

class _FocusableFeedbackRowState extends State<_FocusableFeedbackRow> {
  late List<FocusNode> _nodes;
  late final FocusScopeNode _rowScope = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.tiles.length, (_) => FocusNode());
    if (_nodes.isNotEmpty) {
      // Autofocus first tile on mount for typing flow
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nodes.first.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _FocusableFeedbackRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiles.length != widget.tiles.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = List.generate(widget.tiles.length, (_) => FocusNode());
      if (_nodes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _nodes.first.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _rowScope.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Allow typing anywhere to flow through focused tile; tap anywhere on row to focus first empty
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final firstEmptyIndex = widget.tiles.indexWhere((t) => t.letter.isEmpty);
        final targetIndex = firstEmptyIndex == -1 ? 0 : firstEmptyIndex;
        _nodes[targetIndex].requestFocus();
      },
      child: FocusScope(
        node: _rowScope,
        autofocus: true,
        child: FeedbackRow(
          tiles: widget.tiles,
          onToggleFeedback: widget.onToggleFeedback,
          onLetterChanged: widget.onLetterChanged,
          maxWidth: widget.maxWidth,
          focusNodes: _nodes,
          lockFirstTile: true,
        ),
      ),
    );
  }
}
