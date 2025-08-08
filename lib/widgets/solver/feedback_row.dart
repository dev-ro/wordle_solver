import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    // Compute side length so that all tiles + gaps fit within maxWidth
    final gap = 8.0;
    final side = (maxWidth - gap * (tiles.length - 1)) / tiles.length;
    final clampedSide = side.clamp(36.0, 64.0);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (int i = 0; i < tiles.length; i++)
          FeedbackTile(
            letter: tiles[i].letter,
            feedback: tiles[i].feedback,
            // Use long-press for feedback toggle; disable single-tap toggle
            onTap: () => onSelect(i),
            onLongPress: () => onToggleFeedback(i),
            onLetterChanged: (v) => onLetterChanged(i, v),
            side: clampedSide,
            focusNode: focusNodes[i],
            onMoveNext: i < tiles.length - 1
                ? () => focusNodes[i + 1].requestFocus()
                : null,
            onMovePrev: i > 0 ? () => focusNodes[i - 1].requestFocus() : null,
            isPrefixLocked: lockFirstTile && i == 0,
            isSelected: selectedIndex == i,
            onDoubleTap: () => onDoubleTap(i),
            onShortcutColor: (fb) => onSelect(i),
          ),
      ],
    );
  }
}
