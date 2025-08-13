import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/solver_state.dart';
import 'feedback_tile.dart';

class FeedbackRow extends StatelessWidget {
  final List<SolverTile> tiles;
  final void Function(int index) onToggleFeedback;
  final void Function(int index, String letter) onLetterChanged;
  final double maxWidth;
  final List<FocusNode> focusNodes;
  final bool lockFirstTile;
  final int? selectedIndex;
  final void Function(int index) onSelect;
  final void Function(int index) onDoubleTap;
  final VoidCallback? onSubmit;
  final ValueChanged<bool>? onTileFocusChange;
  final void Function(int index, int digit)? onDigitShortcut;
  final VoidCallback? onBackspaceAtEmpty;
  // Optional arrow navigation callbacks (used when a tile has focus)
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowRight;

  const FeedbackRow({
    super.key,
    required this.tiles,
    required this.onToggleFeedback,
    required this.onLetterChanged,
    required this.maxWidth,
    required this.focusNodes,
    required this.lockFirstTile,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDoubleTap,
    this.onSubmit,
    this.onTileFocusChange,
    this.onDigitShortcut,
    this.onBackspaceAtEmpty,
    this.onArrowLeft,
    this.onArrowRight,
  });

  @override
  Widget build(BuildContext context) {
    // Compute responsive side and gap so row fits within maxWidth without wrapping up to 20 tiles
    double gap = 8.0;
    double side = (maxWidth - gap * (tiles.length - 1)) / tiles.length;
    // If tiles are too small, reduce gap first to preserve legibility
    if (side < 36.0) {
      final reducedGap =
          (maxWidth / tiles.length) * 0.06; // ~6% of per-tile width budget
      gap = reducedGap.clamp(2.0, 8.0);
      side = (maxWidth - gap * (tiles.length - 1)) / tiles.length;
    }
    final clampedSide = side.clamp(28.0, 64.0);

    return SizedBox(
      width: maxWidth,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
            onArrowLeft?.call();
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): () {
            onArrowRight?.call();
          },
        },
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: 0,
          children: [
            for (int i = 0; i < tiles.length; i++)
              FeedbackTile(
                letter: tiles[i].letter,
                feedback: tiles[i].feedback,
                // Single tap selects; double tap cycles colors; long-press focuses keyboard only
                onTap: () => onSelect(i),
                onLongPress: null,
                onLetterChanged: (v) => onLetterChanged(i, v),
                side: clampedSide.toDouble(),
                focusNode: focusNodes[i],
                onMoveNext: i < tiles.length - 1
                    ? () => focusNodes[i + 1].requestFocus()
                    : null,
                onMovePrev: i > 0
                    ? () => focusNodes[i - 1].requestFocus()
                    : null,
                isPrefixLocked: lockFirstTile && i == 0,
                isSelected: selectedIndex == i,
                onDoubleTap: () => onDoubleTap(i),
                onSubmit: onSubmit,
                onFocusChange: onTileFocusChange,
                onDigitShortcut: onDigitShortcut == null
                    ? null
                    : (d) => onDigitShortcut!(i, d),
                onBackspaceAtEmpty: onBackspaceAtEmpty,
              ),
          ],
        ),
      ),
    );
  }
}
