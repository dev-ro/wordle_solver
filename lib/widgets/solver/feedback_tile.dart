import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final bool isPrefixLocked;
  final bool isSelected;
  final VoidCallback? onDoubleTap;

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
    this.isPrefixLocked = false,
    this.isSelected = false,
    this.onDoubleTap,
  });

  Color _bgColor(BuildContext context) {
    switch (feedback) {
      case TileFeedback.green:
        return const Color(0xFF2E7D32); // deeper green for dark theme
      case TileFeedback.yellow:
        return const Color(0xFFF9A825); // deeper amber
      case TileFeedback.black:
        return const Color(0xFF1C1D22);
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
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            controller.text.isEmpty) {
          onMovePrev?.call();
          return KeyEventResult.handled;
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
        readOnly: isPrefixLocked,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
        ],
        onChanged: (v) {
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
              color: isSelected
                  ? const Color(0xFF89CFF0)
                  : (isPrefixLocked ? const Color(0xFF89CFF0) : Colors.white24),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: textField,
        ),
        // Overlay tap target so a single tap toggles feedback regardless of TextField gestures
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // Tap to select; double tap cycles; long press also cycles
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress ?? onDoubleTap ?? onTap,
          ),
        ),
      ],
    );

    return child;
  }
}
