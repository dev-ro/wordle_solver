import 'package:flutter/material.dart';

import '../../state/solver_state.dart';

class FeedbackTile extends StatelessWidget {
  final String letter;
  final TileFeedback feedback;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String> onLetterChanged;
  final double side;
  final FocusNode focusNode;
  final VoidCallback? onMoveNext;
  final VoidCallback? onMovePrev;

  const FeedbackTile({
    super.key,
    required this.letter,
    required this.feedback,
    this.onTap,
    this.onLongPress,
    required this.onLetterChanged,
    required this.side,
    required this.focusNode,
    this.onMoveNext,
    this.onMovePrev,
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
    final controller = TextEditingController(text: letter.toUpperCase());
    final textField = Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        // Handle backspace navigation when empty
        if (event.logicalKey.keyLabel.toLowerCase() == 'backspace' &&
            controller.text.isEmpty) {
          onMovePrev?.call();
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLength: 1,
        decoration: const InputDecoration(counterText: ''),
        style: TextStyle(
          color: _fgColor(context),
          fontSize: side * 0.4,
          fontWeight: FontWeight.bold,
        ),
        controller: controller,
        onChanged: (v) {
          // Store lowercase in state
          onLetterChanged(v.toLowerCase());
          if (v.isNotEmpty) {
            onMoveNext?.call();
          }
        },
      ),
    );

    final child = Stack(
      children: [
        Container(
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
        ),
        // Overlay tap target so a single tap toggles feedback regardless of TextField gestures
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ],
    );

    return child;
  }
}


