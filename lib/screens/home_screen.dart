import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/solver_state.dart';
import '../widgets/solver/feedback_row.dart';
import '../widgets/solver/recommendations_panel.dart';
import '../widgets/solver/filler_results.dart';
import '../state/filler_state.dart';
import '../widgets/common/aurora.dart';
import '../widgets/common/footer.dart';
import '../widgets/common/bokeh_background.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(solverControllerProvider);
    final controller = ref.read(solverControllerProvider.notifier);
    final gridKeyFocus = ref.watch(gridKeyboardFocusNodeProvider);

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
              _RecommendationsSection(state: state, controller: controller),
              const DeveloperFooter(),
            ],
          ),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            const BokehBackground(),
            // Global keyboard listener (desktop/web) remains enabled, but mobile soft keyboards
            // won't deliver RawKeyEvents. Row-level Focus handler (below) also handles keys so
            // typing works when a tile TextField holds focus.
            KeyboardListener(
              focusNode: gridKeyFocus,
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent) return;
                final key = event.logicalKey;
                final keyLabel = key.keyLabel;
                // Arrow navigation always allowed (may land on green tiles)
                if (key == LogicalKeyboardKey.arrowLeft) {
                  controller.moveSelectionLeft();
                  return;
                }
                if (key == LogicalKeyboardKey.arrowRight) {
                  controller.moveSelectionRight();
                  return;
                }
                final tileFocused = ref.read(tileFocusActiveProvider);
                if (tileFocused) {
                  // Let row-level/tile handle other keys when a tile is focused
                  return;
                }
                // Numeric shortcuts for feedback colors and reset
                if (key == LogicalKeyboardKey.digit1 ||
                    key == LogicalKeyboardKey.numpad1) {
                  controller.setFeedbackAtSelection(TileFeedback.green);
                  return;
                }
                if (key == LogicalKeyboardKey.digit2 ||
                    key == LogicalKeyboardKey.numpad2) {
                  controller.setFeedbackAtSelection(TileFeedback.yellow);
                  return;
                }
                if (key == LogicalKeyboardKey.digit3 ||
                    key == LogicalKeyboardKey.numpad3) {
                  controller.setFeedbackAtSelection(TileFeedback.black);
                  return;
                }
                if (key == LogicalKeyboardKey.digit0 ||
                    key == LogicalKeyboardKey.numpad0) {
                  controller.resetCurrentRowFeedbackToBlack();
                  return;
                }
                // Letters/backspace/enter when no tile focused
                if (keyLabel.length == 1 &&
                    RegExp(r'^[A-Za-z]$').hasMatch(keyLabel)) {
                  controller.typeLetterAtSelection(keyLabel);
                } else if (key == LogicalKeyboardKey.backspace) {
                  controller.backspaceAtSelection();
                } else if (key == LogicalKeyboardKey.enter ||
                    key == LogicalKeyboardKey.numpadEnter) {
                  // Gate submit: only when current row is complete
                  final current = state.grid.isNotEmpty
                      ? state.grid.last
                      : const <SolverTile>[];
                  final isComplete =
                      current.isNotEmpty &&
                      !current.any((t) => t.letter.isEmpty);
                  if (isComplete) {
                    _gridSubmitWithFeedbackCheck(
                      context,
                      state,
                      controller,
                      onNewGame: () {
                        // Mirror New button behavior
                        controller.resetGame();
                        ref
                            .read(fillerControllerProvider.notifier)
                            .setQuery('', config: state.config);
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a complete word to submit'),
                        duration: Duration(milliseconds: 1200),
                      ),
                    );
                  }
                }
              },
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight + 18),
                  child: _AppBarWithHelp(),
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppBarWithHelp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AuroraAppBar(title: 'WORDLE SOLVER'),
        // Right-aligned help button overlay within the same app bar area
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Semantics(
                button: true,
                label: 'Help and keyboard shortcuts',
                child: IconButton(
                  tooltip: 'Help and keyboard shortcuts',
                  icon: const Icon(Icons.help_outline, color: Colors.white70),
                  onPressed: () {
                    final isIOS =
                        Theme.of(context).platform == TargetPlatform.iOS;
                    if (isIOS) {
                      showCupertinoDialog(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: const Text('Keyboard shortcuts'),
                          content: const Text(
                            'Type a letter, then press the color number:\n\n'
                            '1: Green (correct)\n'
                            '2: Yellow (present elsewhere)\n'
                            '3: Black/Gray (absent)\n'
                            '0: Reset current row to Black',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Keyboard shortcuts'),
                          content: const SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Type a letter, then press the color number:',
                                ),
                                SizedBox(height: 12),
                                Text('1: Green (correct)'),
                                Text('2: Yellow (present elsewhere)'),
                                Text('3: Black/Gray (absent)'),
                                SizedBox(height: 8),
                                Text('0: Reset current row to Black'),
                                SizedBox(height: 12),
                                Text('Example: A -> 1, D -> 2, I, E, U'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopControls extends ConsumerWidget {
  final SolverUiState state;
  final SolverController controller;

  const _TopControls({required this.state, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillerState = ref.watch(fillerControllerProvider);
    final fillerCtrl = ref.read(fillerControllerProvider.notifier);
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
                    Text(
                      'Length: ${state.config.wordLength}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, c) {
                        // Responsive discrete selector: values 4..15 in a wrap/grid-like layout
                        final values = List<int>.generate(12, (i) => 4 + i);
                        final isNarrow = c.maxWidth < 480;
                        final buttonStyle = FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 8 : 10,
                            vertical: isNarrow ? 8 : 10,
                          ),
                          visualDensity: isNarrow
                              ? const VisualDensity(
                                  horizontal: -2,
                                  vertical: -2,
                                )
                              : VisualDensity.compact,
                          minimumSize: const Size(0, 0),
                        );
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final len in values)
                              SizedBox(
                                width: isNarrow
                                    ? (c.maxWidth - 6 * 3) / 4
                                    : null,
                                child: FilledButton.tonal(
                                  style: buttonStyle,
                                  onPressed: () {
                                    controller.setWordLength(len);
                                    final newConfig = state.config.copyWith(
                                      wordLength: len,
                                      prefix: null,
                                    );
                                    fillerCtrl.setQuery('', config: newConfig);
                                  },
                                  child: Text(
                                    '$len',
                                    style: TextStyle(
                                      fontWeight: len == state.config.wordLength
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Prefix chip removed; prefix control is now an action button below the board
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
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
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Tooltip(
                  message:
                      "Type letters like 'bhptw'. Results rank by coverage and ignore prefix/prior guesses.",
                  child: Consumer(
                    builder: (context, ref, _) {
                      final textCtrl = ref.watch(
                        fillerQueryTextControllerProvider,
                      );
                      return TextField(
                        controller: textCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Search fillers',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        onChanged: (v) =>
                            fillerCtrl.setQuery(v, config: state.config),
                        style: const TextStyle(color: Colors.white),
                        onEditingComplete: () {
                          final node = ref.read(gridKeyboardFocusNodeProvider);
                          FocusScope.of(context).requestFocus(node);
                        },
                        onSubmitted: (_) {
                          final node = ref.read(gridKeyboardFocusNodeProvider);
                          FocusScope.of(context).requestFocus(node);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Auto-copy',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Switch.adaptive(
                      value: state.config.autoCopyOnSelect,
                      onChanged: (v) => controller.setAutoCopyOnSelect(v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fillerState.query.isNotEmpty)
                    FillerResults(
                      title: 'Filler words',
                      results: fillerState.manualResults,
                      denominator: fillerState.query.trim().isEmpty
                          ? null
                          : fillerState.query.trim().split('').toSet().length,
                      onSelectWord: (word) {
                        // Apply filler: set all tiles to black and letters
                        final solverCtrl = ref.read(
                          solverControllerProvider.notifier,
                        );
                        solverCtrl.applyFillerWord(word);
                        // Focus first tile for immediate coloring
                        solverCtrl.selectTile(0);
                        if (state.config.autoCopyOnSelect) {
                          final textToCopy = '!${word.toLowerCase()}';
                          Clipboard.setData(ClipboardData(text: textToCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(milliseconds: 1200),
                              content: Text('Copied filler to clipboard'),
                            ),
                          );
                        }
                        // Return keyboard handling to grid
                        final node = ref.read(gridKeyboardFocusNodeProvider);
                        FocusScope.of(context).requestFocus(node);
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GridSection extends StatefulWidget {
  final SolverUiState state;
  final SolverController controller;

  const _GridSection({required this.state, required this.controller});
  @override
  State<_GridSection> createState() => _GridSectionState();
}

class _GridSectionState extends State<_GridSection> {
  // Stable keys per row index to avoid transferring state when rows are added
  final Map<int, GlobalKey<_FocusableFeedbackRowState>> _rowKeys = {};

  GlobalKey<_FocusableFeedbackRowState> _getOrCreateRowKey(int index) {
    return _rowKeys.putIfAbsent(
      index,
      () => GlobalKey<_FocusableFeedbackRowState>(),
    );
  }

  void _focusActiveRowFirstEmpty() {
    final rowCount = widget.state.grid.length;
    if (rowCount == 0) return;
    _rowKeys[rowCount - 1]?.currentState?.focusFirstEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width <= 480;
    final compactButtonStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 12,
        vertical: isNarrow ? 8 : 10,
      ),
      minimumSize: Size(isNarrow ? 0 : 0, isNarrow ? 36 : 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: isNarrow
          ? const VisualDensity(horizontal: -2, vertical: -2)
          : null,
    );

    final labelTextStyle = isNarrow ? const TextStyle(fontSize: 12) : null;

    final state = widget.state;
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuroraCard(
          child: Column(
            children: [
              // Board tap area: tap or long-press anywhere to focus first empty tile
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _focusActiveRowFirstEmpty,
                onLongPress: _focusActiveRowFirstEmpty,
                child: LayoutBuilder(
                  builder: (context, c) {
                    // Prune keys for rows that no longer exist
                    _rowKeys.removeWhere(
                      (index, _) => index >= state.grid.length,
                    );
                    return Column(
                      children: [
                        for (int r = 0; r < state.grid.length; r++) ...[
                          if (r == state.grid.length - 1)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _FocusableFeedbackRow(
                                    key: _getOrCreateRowKey(r),
                                    tiles: state.grid[r],
                                    onToggleFeedback: (i) =>
                                        controller.toggleFeedback(i),
                                    onLetterChanged: (i, v) =>
                                        controller.overwriteLetterAtIndex(i, v),
                                    // Reserve space for the trailing icon button
                                    maxWidth: c.maxWidth - 32 - 48,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message:
                                      'Toggle all tiles in current word between Green and Black',
                                  child: IconButton(
                                    icon: const Icon(Icons.task_alt_rounded),
                                    onPressed: () {
                                      controller.toggleAllGreenForCurrentRow();
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            _FocusableFeedbackRow(
                              key: _getOrCreateRowKey(r),
                              tiles: state.grid[r],
                              onToggleFeedback: (i) =>
                                  controller.toggleFeedback(i),
                              onLetterChanged: (i, v) =>
                                  controller.overwriteLetterAtIndex(i, v),
                              maxWidth: c.maxWidth - 32, // inner padding margin
                            ),
                          if (r != state.grid.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Color selector: Green, Yellow (tap same color twice -> black)
              Center(
                child: Wrap(
                  spacing: 12,
                  children: [
                    Tooltip(
                      message: 'Mark selected letter as Green (1)',
                      child: _ColorPickTile(
                        color: const Color(0xFF2E7D32),
                        borderColor: Colors.white24,
                        onTap: () {
                          // Safely resolve the target index within the current row
                          if (state.grid.isEmpty || state.grid.last.isEmpty) {
                            return;
                          }
                          int idx = state.selectedIndex ?? 0;
                          final lastRow = state.grid.last;
                          if (idx < 0 || idx >= lastRow.length) {
                            idx = 0;
                          }
                          final current = lastRow[idx].feedback;
                          controller.setTileFeedback(
                            idx,
                            current == TileFeedback.green
                                ? TileFeedback.black
                                : TileFeedback.green,
                          );
                        },
                      ),
                    ),
                    Tooltip(
                      message: 'Mark selected letter as Yellow (2)',
                      child: _ColorPickTile(
                        color: const Color(0xFFF9A825),
                        borderColor: Colors.white24,
                        onTap: () {
                          // Safely resolve the target index within the current row
                          if (state.grid.isEmpty || state.grid.last.isEmpty) {
                            return;
                          }
                          int idx = state.selectedIndex ?? 0;
                          final lastRow = state.grid.last;
                          if (idx < 0 || idx >= lastRow.length) {
                            idx = 0;
                          }
                          final current = lastRow[idx].feedback;
                          controller.setTileFeedback(
                            idx,
                            current == TileFeedback.yellow
                                ? TileFeedback.black
                                : TileFeedback.yellow,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, c) {
                  const spacing = 8.0;
                  // Build action buttons list once
                  final buttons = <Widget>[
                    // Prefix action button
                    Consumer(
                      builder: (context, ref, _) {
                        final hasPrefix =
                            (state.config.prefix ?? '').isNotEmpty;
                        final label = hasPrefix
                            ? 'Clear: ${(state.config.prefix ?? '').toUpperCase()}'
                            : 'Prefix';
                        final tooltip = hasPrefix
                            ? 'Clear the deduced prefix and unlock first tile'
                            : 'The first green letter (prefix) deduced after your first green';
                        return Tooltip(
                          message: tooltip,
                          child: ElevatedButton.icon(
                            style: compactButtonStyle,
                            onPressed: hasPrefix
                                ? () {
                                    controller.clearPrefix();
                                    final focusNode = ref.read(
                                      gridKeyboardFocusNodeProvider,
                                    );
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(focusNode);
                                  }
                                : null,
                            icon: Icon(
                              hasPrefix ? Icons.clear : Icons.font_download,
                              size: isNarrow ? 18 : null,
                            ),
                            label: Text(label, style: labelTextStyle),
                          ),
                        );
                      },
                    ),
                    // Confirm button
                    Builder(
                      builder: (context) {
                        final current = state.grid.isNotEmpty
                            ? state.grid.last
                            : const <SolverTile>[];
                        final isComplete =
                            current.isNotEmpty &&
                            !current.any((t) => t.letter.isEmpty);
                        final guess = current.isNotEmpty
                            ? current.map((t) => t.letter).join()
                            : '';
                        final remaining =
                            state.lastResponse?.remainingWords ??
                            const <String>[];
                        final recommended =
                            state.lastResponse?.recommendations
                                .map((r) => r.word)
                                .toList(growable: false) ??
                            const <String>[];
                        final hasHistory = state.grid.length > 1;
                        final isInRemaining = remaining.contains(guess);
                        final isInRecommended = recommended.contains(guess);
                        final canConfirm =
                            isComplete &&
                            (isInRemaining ||
                                isInRecommended ||
                                (!hasHistory && guess.isNotEmpty));

                        final tooltipMsg = canConfirm
                            ? (!hasHistory && !isInRemaining
                                  ? 'Confirm first-try win'
                                  : 'Confirm win with current word')
                            : 'Enter a complete valid word to enable Confirm';

                        return Tooltip(
                          message: tooltipMsg,
                          child: ElevatedButton.icon(
                            style: compactButtonStyle,
                            onPressed: canConfirm
                                ? () async {
                                    if (!hasHistory && !isInRemaining) {
                                      final proceed = await _confirmFirstTryWin(
                                        context,
                                        guess,
                                      );
                                      if (!proceed || !context.mounted) return;
                                      controller.confirmWin();
                                      return;
                                    }

                                    final ok = await controller
                                        .canConfirmWinWithCurrentRowWord();
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Word conflicts with previous feedback',
                                          ),
                                          duration: Duration(
                                            milliseconds: 1500,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    controller.confirmWin();
                                  }
                                : null,
                            icon: Icon(
                              Icons.check_circle,
                              size: isNarrow ? 18 : null,
                            ),
                            label: Text('Confirm', style: labelTextStyle),
                          ),
                        );
                      },
                    ),
                    // New button
                    Consumer(
                      builder: (context, ref, _) {
                        final fillerCtrl = ref.read(
                          fillerControllerProvider.notifier,
                        );
                        return Tooltip(
                          message: 'Start a new game (reset board)',
                          child: ElevatedButton.icon(
                            style: compactButtonStyle,
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    controller.resetGame();
                                    fillerCtrl.setQuery(
                                      '',
                                      config: state.config,
                                    );
                                  },
                            icon: Icon(
                              Icons.refresh,
                              size: isNarrow ? 18 : null,
                            ),
                            label: Text('New', style: labelTextStyle),
                          ),
                        );
                      },
                    ),
                    // Suggest button
                    Consumer(
                      builder: (context, ref, _) {
                        final fillerCtrl = ref.read(
                          fillerControllerProvider.notifier,
                        );
                        final remainingCount =
                            state.lastResponse?.remainingCount ?? 999;
                        final varPosCount =
                            state.lastResponse?.variablePositions.length ?? 99;
                        final canSuggest =
                            (remainingCount <= 20) &&
                            (varPosCount >= 1 && varPosCount <= 2);
                        final tooltip = canSuggest
                            ? 'Auto-suggest filler words based on remaining candidates'
                            : 'Enabled when remaining words <= 20 and 1–2 variable positions remain';
                        return Tooltip(
                          message: tooltip,
                          child: ElevatedButton.icon(
                            style: compactButtonStyle,
                            onPressed: state.isLoading || !canSuggest
                                ? null
                                : () async {
                                    // Capture platform synchronously before awaiting to satisfy analyzer
                                    final bool isIOSPlatform =
                                        Theme.of(context).platform ==
                                        TargetPlatform.iOS;
                                    final remaining =
                                        state.lastResponse?.remainingWords ??
                                        const <String>[];
                                    // Omit letters known green in this game
                                    final omit = ref
                                        .read(solverControllerProvider.notifier)
                                        .getKnownGreenLetters();
                                    await fillerCtrl.computeAutoSuggest(
                                      config: state.config,
                                      remainingCandidates: remaining,
                                      omitLetters: omit,
                                    );
                                    final letters = ref
                                        .read(fillerControllerProvider.notifier)
                                        .lastAutoSuggestLetters;
                                    if (letters.trim().length <= 2) {
                                      if (!context.mounted) return;
                                      if (isIOSPlatform) {
                                        await showCupertinoDialog<void>(
                                          context: context,
                                          builder: (ctx) =>
                                              const CupertinoAlertDialog(
                                                title: Text(
                                                  'Need at least 3 letters',
                                                ),
                                                content: Text(
                                                  'Suggest works best when there are 3 or more letters to search.',
                                                ),
                                              ),
                                        );
                                      } else {
                                        await showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Need at least 3 letters',
                                            ),
                                            content: const Text(
                                              'Suggest works best when there are 3 or more letters to search.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    fillerCtrl.setQuery(
                                      letters,
                                      config: state.config,
                                    );
                                  },
                            icon: Icon(
                              Icons.auto_awesome,
                              size: isNarrow ? 18 : null,
                            ),
                            label: Text('Suggest', style: labelTextStyle),
                          ),
                        );
                      },
                    ),
                    // Submit button
                    Builder(
                      builder: (context) {
                        final current = state.grid.isNotEmpty
                            ? state.grid.last
                            : const <SolverTile>[];
                        final canSubmit =
                            !state.isLoading &&
                            current.isNotEmpty &&
                            !current.any((t) => t.letter.isEmpty);
                        return Tooltip(
                          message: canSubmit
                              ? 'Submit current guess (Enter)'
                              : 'Enter a complete word to enable Submit',
                          child: Consumer(
                            builder: (context, ref, _) {
                              final fillerCtrl = ref.read(
                                fillerControllerProvider.notifier,
                              );
                              return ElevatedButton.icon(
                                style: compactButtonStyle,
                                onPressed: canSubmit
                                    ? () => _gridSubmitWithFeedbackCheck(
                                        context,
                                        state,
                                        controller,
                                        onNewGame: () {
                                          controller.resetGame();
                                          fillerCtrl.setQuery(
                                            '',
                                            config: state.config,
                                          );
                                        },
                                      )
                                    : null,
                                icon: state.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.send_rounded,
                                        size: isNarrow ? 18 : null,
                                      ),
                                label: Text('Submit', style: labelTextStyle),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ];

                  final children = isNarrow
                      ? buttons
                            .map(
                              (w) => SizedBox(
                                width: (c.maxWidth - spacing * 2) / 3,
                                child: w,
                              ),
                            )
                            .toList()
                      : buttons;

                  return Wrap(
                    alignment: isNarrow
                        ? WrapAlignment.center
                        : WrapAlignment.end,
                    spacing: spacing,
                    runSpacing: spacing,
                    children: children,
                  );
                },
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

class _ColorPickTile extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _ColorPickTile({
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsSection extends ConsumerWidget {
  final SolverUiState state;
  final SolverController controller;

  const _RecommendationsSection({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuroraCard(
      child: RecommendationsPanel(
        response: state.lastResponse,
        isLoading: state.isLoading,
        onSelectWord: (word) {
          controller.applyWordToCurrentRow(word);
          // After applying a word from recommendations, focus first tile
          // to allow immediate coloring from the start.
          // Use the grid keyboard focus scope: select index 0.
          controller.selectTile(0);
          final node = ref.read(gridKeyboardFocusNodeProvider);
          FocusScope.of(context).requestFocus(node);
          if (state.config.autoCopyOnSelect) {
            final textToCopy = '!${word.toLowerCase()}';
            Clipboard.setData(ClipboardData(text: textToCopy));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${word.toLowerCase()} copied to clipboard!'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
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
    super.key,
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

  // Allow parent containers to programmatically focus the first empty tile
  void focusFirstEmpty() {
    if (_nodes.isEmpty) return;
    final firstEmptyIndex = widget.tiles.indexWhere((t) => t.letter.isEmpty);
    final targetIndex = firstEmptyIndex == -1 ? 0 : firstEmptyIndex;
    _nodes[targetIndex].requestFocus();
  }

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
    return Consumer(
      builder: (context, ref, _) {
        final uiState = ref.watch(solverControllerProvider);
        final ctrl = ref.read(solverControllerProvider.notifier);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final firstEmptyIndex = widget.tiles.indexWhere(
              (t) => t.letter.isEmpty,
            );
            final targetIndex = firstEmptyIndex == -1 ? 0 : firstEmptyIndex;
            _nodes[targetIndex].requestFocus();
          },
          onLongPress: () {
            final firstEmptyIndex = widget.tiles.indexWhere(
              (t) => t.letter.isEmpty,
            );
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
              // Unlock prefix tile when a filler was just applied
              lockFirstTile:
                  (uiState.config.prefix ?? '').isNotEmpty &&
                  !uiState.unlockPrefixThisRow,
              selectedIndex: uiState.selectedIndex,
              onSelect: (i) {
                ctrl.selectTile(i);
              },
              onDoubleTap: (i) {
                ctrl.cycleFeedback(i);
              },
              onSubmit: () {
                _gridSubmitWithFeedbackCheck(
                  context,
                  uiState,
                  ctrl,
                  onNewGame: () {
                    ctrl.resetGame();
                    ref
                        .read(fillerControllerProvider.notifier)
                        .setQuery('', config: uiState.config);
                  },
                );
              },
              onTileFocusChange: (hasFocus) {
                ref.read(tileFocusActiveProvider.notifier).state = hasFocus;
              },
              onDigitShortcut: (tileIndex, d) {
                // Handle mobile digit shortcut from tile input
                // Always apply color to the intended letter tile:
                // use setFeedbackAtSelection so if the current selection advanced
                // to an empty tile after typing, the controller will target the
                // last non-empty tile automatically.
                switch (d) {
                  case 1:
                    ctrl.setFeedbackAtSelection(TileFeedback.green);
                    break;
                  case 2:
                    ctrl.setFeedbackAtSelection(TileFeedback.yellow);
                    break;
                  case 3:
                    ctrl.setFeedbackAtSelection(TileFeedback.black);
                    break;
                  case 0:
                    ctrl.resetCurrentRowFeedbackToBlack();
                    break;
                }
              },
              onBackspaceAtEmpty: () {
                // When a tile is focused and empty, a backspace should delete the previous letter
                // and move the selection left (controller handles both behaviors).
                ctrl.backspaceAtSelection();
                // After controller updates selectedIndex, sync actual focus to that index.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final idx =
                      ref.read(solverControllerProvider).selectedIndex ?? 0;
                  if (_nodes.isEmpty) return;
                  final clamped = idx.clamp(0, _nodes.length - 1);
                  _nodes[clamped].requestFocus();
                });
              },
              onArrowLeft: () {
                ctrl.moveSelectionLeft();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final idx =
                      ref.read(solverControllerProvider).selectedIndex ?? 0;
                  if (_nodes.isEmpty) return;
                  final clamped = idx.clamp(0, _nodes.length - 1);
                  _nodes[clamped].requestFocus();
                });
              },
              onArrowRight: () {
                ctrl.moveSelectionRight();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final idx =
                      ref.read(solverControllerProvider).selectedIndex ?? 0;
                  if (_nodes.isEmpty) return;
                  final clamped = idx.clamp(0, _nodes.length - 1);
                  _nodes[clamped].requestFocus();
                });
              },
            ),
          ),
        );
      },
    );
  }
}

// Platform-aware first-try win confirmation dialog
Future<bool> _confirmFirstTryWin(BuildContext context, String guess) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  if (isIOS) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Confirm first-try win'),
            content: Text('Confirm that "$guess" is the correct word?'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: false,
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  } else {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm first-try win'),
            content: Text('Confirm that "$guess" is the correct word?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// Top-level helper so both the screen-level and row-level handlers can invoke the same
// confirmation flow before submitting when all tiles are black.
Future<void> _gridSubmitWithFeedbackCheck(
  BuildContext context,
  SolverUiState uiState,
  SolverController ctrl, {
  VoidCallback? onNewGame,
}) async {
  // Prevent concurrent submissions
  if (uiState.isLoading) return;
  final current = uiState.grid.isNotEmpty
      ? uiState.grid.last
      : const <SolverTile>[];
  final allBlack =
      current.isNotEmpty &&
      current.every((t) => t.feedback == TileFeedback.black);
  if (!allBlack) {
    if (uiState.isLoading) return;
    // If all tiles are green (confirmed win), treat submit as New
    final allGreen =
        current.isNotEmpty &&
        current.every((t) => t.feedback == TileFeedback.green);
    if (allGreen) {
      onNewGame?.call();
      return;
    }
    ctrl.requestRecommendations();
    return;
  }
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  bool proceed = false;
  if (isIOS) {
    proceed =
        await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('All tiles are black'),
            content: const Text(
              'You have not set any feedback colors. Submit anyway?',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: false,
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Set colors'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Submit'),
              ),
            ],
          ),
        ) ??
        false;
  } else {
    proceed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('All tiles are black'),
            content: const Text(
              'You have not set any feedback colors. Submit anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Set colors'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Submit'),
              ),
            ],
          ),
        ) ??
        false;
  }
  if (proceed) {
    if (uiState.isLoading) return;
    ctrl.requestRecommendations();
  }
}
