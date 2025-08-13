import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/solver_state.dart';

class FeedbackTile extends StatefulWidget {
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
  final VoidCallback? onBackspaceAtEmpty;

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
    this.onBackspaceAtEmpty,
  });

  @override
  State<FeedbackTile> createState() => _FeedbackTileState();
}

class _FeedbackTileState extends State<FeedbackTile> {
  static const String _sentinel = '\u200B';
  late final TextEditingController _controller;
  bool _isSettingText = false;

  void _notifyFocusChange() {
    final hasFocus = widget.focusNode.hasFocus;
    widget.onFocusChange?.call(hasFocus);
    if (hasFocus) {
      // Ensure caret is at the end so backspace deletes the last code unit.
      // Also ensure sentinel exists for empty tiles so backspace yields onChanged.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.letter.isEmpty && _controller.text != _sentinel) {
          _isSettingText = true;
          _controller.text = _sentinel;
          _isSettingText = false;
        }
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.letter.isEmpty ? _sentinel : widget.letter.toUpperCase(),
    );
    widget.focusNode.addListener(_notifyFocusChange);
  }

  @override
  void didUpdateWidget(covariant FeedbackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_notifyFocusChange);
      widget.focusNode.addListener(_notifyFocusChange);
    }
    if (oldWidget.letter != widget.letter) {
      // Keep controller in sync with external model while avoiding feedback loops.
      final newText = widget.letter.isEmpty
          ? _sentinel
          : widget.letter.toUpperCase();
      if (_controller.text != newText) {
        _isSettingText = true;
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        _isSettingText = false;
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_notifyFocusChange);
    _controller.dispose();
    super.dispose();
  }

  Color _bgColor(BuildContext context) {
    switch (widget.feedback) {
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
    // Controller is stateful to avoid recreating and to support focus-caret fixes.
    // Only prefix should lock; currently not used to block tap behavior
    final theme = Theme.of(context);
    final Color selectedBorder = theme.colorScheme.primary;
    final Color prefixBorder = theme.colorScheme.tertiary;
    final double selectedBorderWidth = 2.0;
    final double normalBorderWidth = 1.2;
    // Invisible input layered under a perfectly centered display text
    final inputField = TextField(
      focusNode: widget.focusNode,
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
        fontSize: widget.side * 0.5,
        fontWeight: FontWeight.bold,
        height: 1.0,
      ),
      controller: _controller,
      // Always editable via keyboard, even when prefix-locked; gestures may still be disabled
      readOnly: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-3\u200B]')),
      ],
      // Arrow keys handled at row level via Shortcuts/Actions
      onChanged: (v) {
        if (_isSettingText) return; // ignore programmatic updates
        // Normalize by removing sentinel
        String raw = v.replaceAll(_sentinel, '');
        if (raw.isEmpty) {
          // Backspace pressed
          if (widget.letter.isEmpty) {
            // Let parent handle controller-selectedIndex change and focus sync.
            // Only fall back to moving UI focus left if no handler is provided.
            if (widget.onBackspaceAtEmpty != null) {
              widget.onBackspaceAtEmpty!.call();
            } else {
              widget.onMovePrev?.call();
            }
          } else {
            widget.onLetterChanged('');
            // Move focus left when deleting a non-empty tile
            widget.onMovePrev?.call();
          }
          // Restore sentinel so further backspaces still trigger changes
          _isSettingText = true;
          _controller.text = _sentinel;
          _controller.selection = const TextSelection.collapsed(offset: 1);
          _isSettingText = false;
          return;
        }
        // If a digit 0-3 was entered anywhere in the string, treat the last char as shortcut
        final lastChar = raw.substring(raw.length - 1);
        if (RegExp(r'^[0-3]$').hasMatch(lastChar)) {
          final d = int.tryParse(lastChar);
          if (d != null) widget.onDigitShortcut?.call(d);
          _isSettingText = true;
          _controller.text = _sentinel;
          _controller.selection = const TextSelection.collapsed(offset: 1);
          _isSettingText = false;
          return;
        }
        // Take last alpha character
        final last = raw.substring(raw.length - 1).toLowerCase();
        if (RegExp(r'^[a-z]$').hasMatch(last)) {
          widget.onLetterChanged(last);
          // Reset field to sentinel so it stays effectively single-char visually
          _isSettingText = true;
          _controller.text = _sentinel;
          _controller.selection = const TextSelection.collapsed(offset: 1);
          _isSettingText = false;
          widget.onMoveNext?.call();
        }
      },
      onEditingComplete: () {
        // Attempt to parse a single digit as a color shortcut (mobile soft keyboard case)
        // Only act if the current value is a digit and then clear it so it doesn't remain
        final text = _controller.text;
        if (text.length == 1 && RegExp(r'^[0-3]$').hasMatch(text)) {
          final d = int.tryParse(text);
          if (d != null) {
            widget.onDigitShortcut?.call(d);
            _controller.clear();
          }
        }
      },
      onSubmitted: (_) => widget.onSubmit?.call(),
    );

    final child = Stack(
      children: [
        Container(
          width: widget.side,
          height: widget.side,
          decoration: BoxDecoration(
            color: _bgColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? selectedBorder
                  : (widget.isPrefixLocked ? prefixBorder : Colors.white24),
              width: widget.isSelected
                  ? selectedBorderWidth
                  : normalBorderWidth,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Display text perfectly centered
              Center(
                child: Text(
                  (widget.letter).toUpperCase(),
                  textAlign: TextAlign.center,
                  strutStyle: StrutStyle(
                    fontSize: widget.side * 0.5,
                    height: 1.0,
                    leading: 0,
                    forceStrutHeight: true,
                  ),
                  style: TextStyle(
                    color: _fgColor(context),
                    fontSize: widget.side * 0.5,
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
            onTap: () async {
              widget.focusNode.requestFocus();
              // Explicitly ask to show the soft keyboard on mobile
              await SystemChannels.textInput.invokeMethod('TextInput.show');
              // Move caret to end
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
              widget.onTap?.call();
            },
            onDoubleTap: () async {
              widget.focusNode.requestFocus();
              await SystemChannels.textInput.invokeMethod('TextInput.show');
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
              widget.onDoubleTap?.call();
            },
            onLongPress: () async {
              widget.focusNode.requestFocus();
              await SystemChannels.textInput.invokeMethod('TextInput.show');
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
              // Long press is keyboard-only; no color cycling here
            },
          ),
        ),
      ],
    );

    return child;
  }
}
