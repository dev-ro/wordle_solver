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
  final VoidCallback? onSubmit;
  final ValueChanged<bool>? onFocusChange;

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
    this.onSubmit,
    this.onFocusChange,
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
    // Always render white text for strong contrast across states
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: letter.toUpperCase());
    // Only prefix should lock; green tiles should remain tappable to cycle colors
    final bool isLocked = isPrefixLocked;
    final theme = Theme.of(context);
    final Color selectedBorder = theme.colorScheme.primary;
    final Color prefixBorder = theme.colorScheme.tertiary;
    final double selectedBorderWidth = 2.0;
    final double normalBorderWidth = 1.2;
    // Invisible input layered under a perfectly centered display text
    final inputField = Focus(
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        // Defer backspace entirely to the global handler so it can clear previous tiles and
        // handle selection consistently across the row. Avoid double-processing here.
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        showCursor: false,
        cursorColor: Colors.transparent,
        enableInteractiveSelection: false,
        autofocus: false,
        // Ensures mobile soft keyboard can appear when tile gains focus
        canRequestFocus: true,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        textCapitalization: TextCapitalization.characters,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: '',
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: TextStyle(
          color: Colors.transparent,
          fontSize: side * 0.5,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
        controller: controller,
        // Always editable via keyboard, even when prefix-locked; gestures may still be disabled
        readOnly: false,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
        ],
        onChanged: (v) {
          onLetterChanged(v.toLowerCase());
          if (v.isNotEmpty) {
            onMoveNext?.call();
          }
        },
        onSubmitted: (_) => onSubmit?.call(),
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
                  ? selectedBorder
                  : (isPrefixLocked ? prefixBorder : Colors.white24),
              width: isSelected ? selectedBorderWidth : normalBorderWidth,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Display text perfectly centered
              Center(
                child: Text(
                  (letter).toUpperCase(),
                  textAlign: TextAlign.center,
                  strutStyle: StrutStyle(
                    fontSize: side * 0.5,
                    height: 1.0,
                    leading: 0,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    color: _fgColor(context),
                    fontSize: side * 0.5,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
              // Invisible full-size input to capture typing and navigation
              Positioned.fill(child: inputField),
            ],
          ),
        ),
        // Overlay tap target: ensure we always focus this tile, then apply gestures
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              focusNode.requestFocus();
              if (!isLocked) {
                onTap?.call();
              }
            },
            onDoubleTap: () {
              focusNode.requestFocus();
              if (!isLocked) {
                onDoubleTap?.call();
              }
            },
            onLongPress: () {
              focusNode.requestFocus();
              if (!isLocked) {
                onLongPress?.call();
              }
            },
          ),
        ),
      ],
    );

    return child;
  }
}
