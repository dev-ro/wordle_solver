import 'package:flutter/material.dart';

import '../../state/solver_state.dart';

class FeedbackTile extends StatelessWidget {
  final String letter;
  final TileFeedback feedback;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String> onLetterChanged;
  final double side;

  const FeedbackTile({
    super.key,
    required this.letter,
    required this.feedback,
    this.onTap,
    this.onLongPress,
    required this.onLetterChanged,
    required this.side,
  });

  Color _bgColor(BuildContext context) {
    switch (feedback) {
      case TileFeedback.green:
        return Colors.green;
      case TileFeedback.yellow:
        return Colors.amber;
      case TileFeedback.black:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _fgColor(BuildContext context) {
    switch (feedback) {
      case TileFeedback.green:
      case TileFeedback.yellow:
        return Colors.black;
      case TileFeedback.black:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      textAlign: TextAlign.center,
      maxLength: 1,
      decoration: const InputDecoration(counterText: ''),
      style: TextStyle(
        color: _fgColor(context),
        fontSize: side * 0.4,
        fontWeight: FontWeight.bold,
      ),
      controller: TextEditingController(text: letter),
      onChanged: onLetterChanged,
    );

    final child = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: _bgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
      alignment: Alignment.center,
      child: textField,
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onLongPress,
      child: child,
    );
  }
}


