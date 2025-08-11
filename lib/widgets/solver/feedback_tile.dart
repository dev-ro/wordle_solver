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
  final void Function(int digit)? onDigitShortcut;

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
    this.onDigitShortcut,
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
    const String sentinel =
        '\u200B'; // zero-width space to detect backspace on empty
    final controller = TextEditingController(
      text: letter.isEmpty ? sentinel : letter.toUpperCase(),
    );
    // Only prefix should lock; currently not used to block tap behavior
    final theme = Theme.of(context);
    final Color selectedBorder = theme.colorScheme.primary;
    final Color prefixBorder = theme.colorScheme.tertiary;
    final double selectedBorderWidth = 2.0;
    final double normalBorderWidth = 1.2;
    // Invisible input layered under a perfectly centered display text
    final inputField = TextField(
      focusNode: focusNode,
      showCursor: false,
      cursorColor: Colors.transparent,
      enableInteractiveSelection: false,
      autofocus: false,
      // Ensures mobile soft keyboard can appear when tile gains focus
      canRequestFocus: true,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      textCapitalization: TextCapitalization.characters,
      // Allow one visible char plus sentinel
      maxLength: 2,
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
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-3\u200B]')),
      ],
      onChanged: (v) {
        // Normalize by removing sentinel
        String raw = v.replaceAll(sentinel, '');
        if (raw.isEmpty) {
          // Backspace on empty: clear this tile and move left
          onLetterChanged('');
          // Restore sentinel so further backspaces still trigger changes
          controller.text = sentinel;
          controller.selection = const TextSelection.collapsed(offset: 1);
          onMovePrev?.call();
          return;
        }
        // If a digit 0-3 was entered, treat as color shortcut and clear input
        if (raw.length == 1 && RegExp(r'^[0-3]$').hasMatch(raw)) {
          final d = int.tryParse(raw);
          if (d != null) onDigitShortcut?.call(d);
          controller.text = sentinel;
          controller.selection = const TextSelection.collapsed(offset: 1);
          return;
        }
        // Take last alpha character
        final last = raw.substring(raw.length - 1).toLowerCase();
        if (RegExp(r'^[a-z]$').hasMatch(last)) {
          onLetterChanged(last);
          // Reset field to sentinel so it stays effectively single-char visually
          controller.text = sentinel;
          controller.selection = const TextSelection.collapsed(offset: 1);
          onMoveNext?.call();
        }
      },
      onEditingComplete: () {
        // Attempt to parse a single digit as a color shortcut (mobile soft keyboard case)
        // Only act if the current value is a digit and then clear it so it doesn't remain
        final text = controller.text;
        if (text.length == 1 && RegExp(r'^[0-3]$').hasMatch(text)) {
          final d = int.tryParse(text);
          if (d != null) {
            onDigitShortcut?.call(d);
            controller.clear();
          }
        }
      },
      onSubmitted: (_) => onSubmit?.call(),
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
          child: Focus(
            onFocusChange: onFocusChange,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                focusNode.requestFocus();
                // Explicitly ask to show the soft keyboard on mobile
                await SystemChannels.textInput.invokeMethod('TextInput.show');
                // Move caret to end
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                onTap?.call();
              },
              onDoubleTap: () async {
                focusNode.requestFocus();
                await SystemChannels.textInput.invokeMethod('TextInput.show');
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                onDoubleTap?.call();
              },
              onLongPress: () async {
                focusNode.requestFocus();
                await SystemChannels.textInput.invokeMethod('TextInput.show');
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                // Long press is keyboard-only; no color cycling here
              },
            ),
          ),
        ),
      ],
    );

    return child;
  }
}
