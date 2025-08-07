import 'package:flutter/material.dart';

import '../../state/solver_state.dart';
import 'feedback_tile.dart';

class FeedbackRow extends StatelessWidget {
  final List<SolverTile> tiles;
  final void Function(int index) onToggleFeedback;
  final void Function(int index, String letter) onLetterChanged;

  const FeedbackRow({
    super.key,
    required this.tiles,
    required this.onToggleFeedback,
    required this.onLetterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth * 0.02;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              FeedbackTile(
                letter: tiles[i].letter,
                feedback: tiles[i].feedback,
                onTap: () => onToggleFeedback(i),
                onLetterChanged: (v) => onLetterChanged(i, v),
              ),
              if (i != tiles.length - 1) SizedBox(width: spacing),
            ]
          ],
        );
      },
    );
  }
}


