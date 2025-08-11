// import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/solver_models.dart';
import '../repositories/solver_repository.dart';
import 'package:flutter/widgets.dart';

enum TileFeedback { black, yellow, green }

TileFeedback nextFeedback(TileFeedback f) {
  switch (f) {
    case TileFeedback.green:
      return TileFeedback.yellow;
    case TileFeedback.yellow:
      return TileFeedback.black;
    case TileFeedback.black:
      return TileFeedback.green;
  }
}

@immutable
class SolverTile {
  final String letter; // single lowercase letter or ''
  final TileFeedback feedback;

  const SolverTile({required this.letter, required this.feedback});

  SolverTile copyWith({String? letter, TileFeedback? feedback}) => SolverTile(
    letter: letter ?? this.letter,
    feedback: feedback ?? this.feedback,
  );
}

@immutable
class SolverUiState {
  final SolverConfig config;
  final List<List<SolverTile>> grid; // history rows + current input row
  final SolverResponse? lastResponse;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedIndex; // selected column index in current input row
  final bool
  currentRowFeedbackTouched; // whether user edited feedback on current row
  final Map<int, String>?
  pendingGreenLocks; // temporary greens when applying filler
  // When true, temporarily unlock the prefix tile (first tile) for the current row.
  // This is set when a filler word is applied so the user can change its color.
  final bool unlockPrefixThisRow;

  const SolverUiState({
    required this.config,
    required this.grid,
    required this.lastResponse,
    required this.isLoading,
    required this.errorMessage,
    required this.selectedIndex,
    required this.currentRowFeedbackTouched,
    this.pendingGreenLocks,
    this.unlockPrefixThisRow = false,
  });

  // Sentinels to allow explicitly setting nullable fields to null while
  // preserving existing values when parameters are omitted.
  static const Object _sentinel = Object();

  SolverUiState copyWith({
    SolverConfig? config,
    List<List<SolverTile>>? grid,
    Object? lastResponse = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    int? selectedIndex,
    bool? currentRowFeedbackTouched,
    Map<int, String>? pendingGreenLocks,
    bool? unlockPrefixThisRow,
  }) {
    return SolverUiState(
      config: config ?? this.config,
      grid: grid ?? this.grid,
      lastResponse: identical(lastResponse, _sentinel)
          ? this.lastResponse
          : lastResponse as SolverResponse?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      currentRowFeedbackTouched:
          currentRowFeedbackTouched ?? this.currentRowFeedbackTouched,
      pendingGreenLocks: pendingGreenLocks ?? this.pendingGreenLocks,
      unlockPrefixThisRow: unlockPrefixThisRow ?? this.unlockPrefixThisRow,
    );
  }
}

class SolverController extends StateNotifier<SolverUiState> {
  final SolverRepository repository;

  SolverController({required this.repository})
    : super(
        SolverUiState(
          config: const SolverConfig(wordLength: 5, dictionary: 'english.json'),
          grid: [
            List.generate(
              5,
              (_) => const SolverTile(letter: '', feedback: TileFeedback.black),
            ),
          ],
          lastResponse: null,
          isLoading: false,
          errorMessage: null,
          selectedIndex: 0,
          currentRowFeedbackTouched: false,
          pendingGreenLocks: null,
          unlockPrefixThisRow: false,
        ),
      );

  void setWordLength(int length) {
    final clamped = length < 3 ? 3 : (length > 20 ? 20 : length);
    final newRow = List.generate(
      clamped,
      (_) => const SolverTile(letter: '', feedback: TileFeedback.black),
    );
    // If we have a 1-char prefix, auto-populate first tile for the current row
    final p = state.config.prefix;
    if (p != null && p.isNotEmpty) {
      newRow[0] = newRow[0].copyWith(
        letter: p[0].toLowerCase(),
        feedback: TileFeedback.green,
      );
    }
    final newGrid = [newRow];
    state = state.copyWith(
      config: state.config.copyWith(wordLength: clamped),
      grid: newGrid,
      lastResponse: null,
      isLoading: false,
      errorMessage: null,
      selectedIndex: 0,
      currentRowFeedbackTouched: false,
      pendingGreenLocks: null,
      unlockPrefixThisRow: false,
    );
  }

  // True when the given column is the prefix-locked tile for the current row
  // and this row has not been explicitly unlocked (e.g., by filler application).
  bool _isPrefixLockedIndex(int colIndex) {
    return (state.config.prefix ?? '').isNotEmpty &&
        colIndex == 0 &&
        !state.unlockPrefixThisRow;
  }

  // Returns true if the tile at the given index is editable in the current row.
  // A tile is not editable when it is green or when it is the first tile with a non-empty prefix lock.
  bool isTileEditable(int colIndex) {
    if (state.grid.isEmpty) return false;
    final currentRow = state.grid.last;
    if (colIndex < 0 || colIndex >= currentRow.length) return false;
    final isPrefixLocked =
        (state.config.prefix ?? '').isNotEmpty && colIndex == 0;
    // Allow editing the prefix tile for this row when explicitly unlocked
    if (isPrefixLocked && state.unlockPrefixThisRow) {
      return true;
    }
    if (isPrefixLocked) return false;
    return currentRow[colIndex].feedback != TileFeedback.green;
  }

  // Find the first editable tile whose letter is empty.
  int? findFirstEditableEmptyIndex() {
    if (state.grid.isEmpty) return null;
    final currentRow = state.grid.last;
    for (int i = 0; i < currentRow.length; i++) {
      if (isTileEditable(i) && currentRow[i].letter.isEmpty) {
        return i;
      }
    }
    return null;
  }

  // Find the last editable tile whose letter is non-empty.
  int? findLastEditableNonEmptyIndex() {
    if (state.grid.isEmpty) return null;
    final currentRow = state.grid.last;
    for (int i = currentRow.length - 1; i >= 0; i--) {
      if (isTileEditable(i) && currentRow[i].letter.isNotEmpty) {
        return i;
      }
    }
    return null;
  }

  // Find previous editable index to the left of startFromExclusive.
  int? findPrevEditableIndex(int startFromExclusive) {
    if (state.grid.isEmpty) return null;
    for (int i = startFromExclusive - 1; i >= 0; i--) {
      if (isTileEditable(i)) return i;
    }
    return null;
  }

  // Find next editable index to the right of startFromExclusive.
  int? findNextEditableIndex(int startFromExclusive) {
    if (state.grid.isEmpty) return null;
    final currentRow = state.grid.last;
    for (int i = startFromExclusive + 1; i < currentRow.length; i++) {
      if (isTileEditable(i)) return i;
    }
    return null;
  }

  // Set the provided single letter at the next available editable empty tile.
  void setLetterAtNextAvailable(String value) {
    if (value.isEmpty) return;
    final lastChar = value.substring(value.length - 1).toLowerCase();
    if (!RegExp(r'^[a-z]$').hasMatch(lastChar)) return;
    final idx = findFirstEditableEmptyIndex();
    if (idx == null) return;
    _updateTile(idx, letter: lastChar);
    state = state.copyWith(selectedIndex: idx);
  }

  // Known green letter at a column from prefix, pending locks, or history.
  String? _knownGreenLetterAt(int colIndex) {
    // Prefix implies first tile is green with its first char
    final p = state.config.prefix;
    if (colIndex == 0 && p != null && p.isNotEmpty) {
      return p[0].toLowerCase();
    }
    // Pending locks captured before filler application
    final pending = state.pendingGreenLocks;
    if (pending != null && pending.containsKey(colIndex)) {
      return pending[colIndex]?.toLowerCase();
    }
    // Scan history rows (exclude current input row)
    if (state.grid.length > 1) {
      for (int r = state.grid.length - 2; r >= 0; r--) {
        final row = state.grid[r];
        if (colIndex >= 0 && colIndex < row.length) {
          final t = row[colIndex];
          if (t.feedback == TileFeedback.green && t.letter.isNotEmpty) {
            return t.letter.toLowerCase();
          }
        }
      }
    }
    return null;
  }

  // New: type a letter at the current selection index, ignoring edit locks.
  // Overwrites any tile (including green or prefix) and then moves selection right.
  void typeLetterAtSelection(String value) {
    if (state.grid.isEmpty || value.isEmpty) return;
    final lastChar = value.substring(value.length - 1).toLowerCase();
    if (!RegExp(r'^[a-z]$').hasMatch(lastChar)) return;
    final currentRow = state.grid.last;
    // Respect the current selection index to support selection-based typing
    int idx = state.selectedIndex ?? 0;
    if (idx < 0 || idx >= currentRow.length) idx = 0;
    final existing = currentRow[idx];
    final known = _knownGreenLetterAt(idx);
    TileFeedback? newFeedback;
    if (known != null && known == lastChar) {
      newFeedback = TileFeedback.green; // auto-green when matching known green
    } else if (existing.feedback == TileFeedback.green &&
        existing.letter != lastChar) {
      newFeedback = TileFeedback.black; // diff from previous green -> black
    }
    _updateTile(idx, letter: lastChar, feedback: newFeedback);
    final next = (idx + 1).clamp(0, currentRow.length - 1);
    state = state.copyWith(selectedIndex: next);
  }

  // Clear the letter at the specified index if editable.
  void clearLetterAtIndex(int colIndex) {
    if (!isTileEditable(colIndex)) return;
    _updateTile(colIndex, letter: '');
    state = state.copyWith(selectedIndex: colIndex);
  }

  // Implements backspace semantics for the current row:
  // - Remove the most recent non-locked letter (rightmost editable non-empty)
  // - If selected tile is empty, jump selection to previous editable tile
  void backspaceAtPreviousEditable() {
    final idx = findLastEditableNonEmptyIndex();
    if (idx != null) {
      clearLetterAtIndex(idx);
      return;
    }
    // Nothing to delete; move selection left if possible
    final currentSelected = state.selectedIndex ?? state.grid.last.length - 1;
    final prev = findPrevEditableIndex(currentSelected + 1);
    if (prev != null) {
      state = state.copyWith(selectedIndex: prev);
    }
  }

  // New: backspace at current selection, ignoring edit locks.
  // Clears the selected tile (even if green/prefix) and moves selection left.
  void backspaceAtSelection() {
    if (state.grid.isEmpty || state.grid.last.isEmpty) return;
    final currentRow = state.grid.last;
    int idx = state.selectedIndex ?? 0;
    if (idx < 0 || idx >= currentRow.length) idx = currentRow.length - 1;

    // If current tile is empty, delete the nearest previous editable non-empty tile.
    if (currentRow[idx].letter.isEmpty) {
      for (int i = idx - 1; i >= 0; i--) {
        // Ignore edit locks here to allow backspacing over locked greens/prefix
        if (currentRow[i].letter.isNotEmpty) {
          _updateTile(i, letter: '', feedback: TileFeedback.black);
          state = state.copyWith(selectedIndex: i);
          return;
        }
      }
      // Nothing to delete; just move selection left if possible
      final prev = (idx - 1).clamp(0, currentRow.length - 1);
      state = state.copyWith(selectedIndex: prev);
      return;
    }

    // Current tile has a letter: clear it and move selection left one.
    _updateTile(idx, letter: '', feedback: TileFeedback.black);
    final prev = (idx - 1).clamp(0, currentRow.length - 1);
    state = state.copyWith(selectedIndex: prev);
  }

  // Overwrite letter at an exact index from tile input.
  // - Always writes the provided letter regardless of feedback/prefix
  // - If the tile was green and the letter changes, reset feedback to black
  // - When clearing (empty value), also reset feedback to black
  void overwriteLetterAtIndex(int colIndex, String value) {
    if (state.grid.isEmpty || state.grid.last.isEmpty) return;
    if (colIndex < 0 || colIndex >= state.grid.last.length) return;
    if (value.isEmpty) {
      _updateTile(colIndex, letter: '', feedback: TileFeedback.black);
      // Keep selection aligned with this tile when cleared; if clearing index 0, stay at 0
      state = state.copyWith(selectedIndex: colIndex > 0 ? colIndex - 1 : 0);
      return;
    }
    final lastChar = value.substring(value.length - 1).toLowerCase();
    if (!RegExp(r'^[a-z]$').hasMatch(lastChar)) return;
    final row = state.grid.last;
    final existing = row[colIndex];
    final known = _knownGreenLetterAt(colIndex);
    TileFeedback? newFeedback;
    if (known != null && known == lastChar) {
      newFeedback = TileFeedback.green;
    } else if (existing.feedback == TileFeedback.green &&
        existing.letter != lastChar) {
      newFeedback = TileFeedback.black;
    }
    _updateTile(colIndex, letter: lastChar, feedback: newFeedback);
    // Move selection to next tile after typing at an index
    final next = (colIndex + 1).clamp(0, row.length - 1);
    state = state.copyWith(selectedIndex: next);
  }

  // Fill the current row with the given word while respecting edit locks.
  // Will not overwrite green tiles or a prefix-locked first tile.
  void applyWordToCurrentRow(String word) {
    if (state.grid.isEmpty) return;
    final rows = List<List<SolverTile>>.from(state.grid.map((r) => List.of(r)));
    final currentRow = List<SolverTile>.from(rows.removeLast());
    int? lastSetIndex;
    for (int i = 0; i < currentRow.length && i < word.length; i++) {
      if (!isTileEditable(i)) continue;
      final ch = word[i].toLowerCase();
      if (!RegExp(r'^[a-z]$').hasMatch(ch)) continue;
      currentRow[i] = currentRow[i].copyWith(letter: ch);
      lastSetIndex = i;
    }
    rows.add(currentRow);
    state = state.copyWith(
      grid: rows,
      selectedIndex: lastSetIndex ?? state.selectedIndex,
      errorMessage: null,
    );
  }

  void setDictionary(String dictionaryName) {
    // Changing dictionary starts a new game: clear prefix and board
    final newConfig = SolverConfig(
      wordLength: state.config.wordLength,
      prefix: null,
      dictionary: dictionaryName,
      autoCopyOnSelect: state.config.autoCopyOnSelect,
    );
    final length = newConfig.wordLength;
    final newRow = List.generate(
      length,
      (_) => const SolverTile(letter: '', feedback: TileFeedback.black),
    );
    state = state.copyWith(
      config: newConfig,
      grid: [newRow],
      lastResponse: null,
      isLoading: false,
      errorMessage: null,
      selectedIndex: 0,
      currentRowFeedbackTouched: false,
      pendingGreenLocks: null,
      unlockPrefixThisRow: false,
    );
  }

  void setAutoCopyOnSelect(bool enabled) {
    final newConfig = state.config.copyWith(autoCopyOnSelect: enabled);
    state = state.copyWith(config: newConfig);
  }

  void setPrefix(String? prefix) {
    // Update config with explicit prefix (allow null to clear)
    final newConfig = SolverConfig(
      wordLength: state.config.wordLength,
      prefix: prefix,
      dictionary: state.config.dictionary,
      autoCopyOnSelect: state.config.autoCopyOnSelect,
    );

    // Reflect prefix into the current input row: auto-fill first letter when present;
    // clear it when prefix is removed
    final rows = List<List<SolverTile>>.from(state.grid.map((r) => List.of(r)));
    if (rows.isNotEmpty && rows.last.isNotEmpty) {
      final currentRow = List<SolverTile>.from(rows.removeLast());
      final firstTile = currentRow.first;
      if (prefix != null && prefix.isNotEmpty) {
        currentRow[0] = firstTile.copyWith(
          letter: prefix[0].toLowerCase(),
          feedback: TileFeedback.green,
        );
      } else {
        currentRow[0] = firstTile.copyWith(
          letter: '',
          feedback: TileFeedback.black,
        );
      }
      rows.add(currentRow);
    }

    state = state.copyWith(config: newConfig, grid: rows, errorMessage: null);
  }

  // Clear the deduced prefix and make the first tile editable again.
  void clearPrefix() {
    setPrefix(null);
    // Ensure selection returns to the first tile for convenient typing
    state = state.copyWith(selectedIndex: 0, unlockPrefixThisRow: false);
  }

  void setLetter(int colIndex, String value) {
    if (value.isEmpty) return _updateTile(colIndex, letter: '');
    final lastChar = value.substring(value.length - 1).toLowerCase();
    if (!RegExp(r'^[a-z] ?$').hasMatch(lastChar)) {
      if (!RegExp(r'^[a-z]$').hasMatch(lastChar)) return;
    }
    _updateTile(colIndex, letter: lastChar.substring(0, 1));
    // Keep selection on the edited tile for color application
    state = state.copyWith(selectedIndex: colIndex);
  }

  void toggleFeedback(int colIndex) {
    if (_isPrefixLockedIndex(colIndex)) return;
    final row = state.grid.last;
    final tile = row[colIndex];
    _updateTile(colIndex, feedback: nextFeedback(tile.feedback));
    state = state.copyWith(currentRowFeedbackTouched: true);
  }

  void cycleFeedback(int colIndex) {
    if (_isPrefixLockedIndex(colIndex)) return;
    toggleFeedback(colIndex);
    state = state.copyWith(selectedIndex: colIndex);
  }

  void setTileFeedback(int colIndex, TileFeedback feedback) {
    if (_isPrefixLockedIndex(colIndex)) return;
    final row = state.grid.last;
    final current = row[colIndex];
    // Toggle: requesting the same color again reverts to black
    final nextColor = (current.feedback == feedback)
        ? TileFeedback.black
        : feedback;
    _updateTile(colIndex, feedback: nextColor);
    state = state.copyWith(
      selectedIndex: colIndex,
      currentRowFeedbackTouched: true,
    );
  }

  // Set feedback color on the most relevant tile for the user's current typing flow.
  // If the currently selected tile is empty (because typing advanced the cursor),
  // prefer the last non-empty editable tile so users can press the color after the letter.
  void setFeedbackAtSelection(TileFeedback feedback) {
    if (state.grid.isEmpty || state.grid.last.isEmpty) return;
    int idx = state.selectedIndex ?? 0;
    final currentRow = state.grid.last;
    if (idx < 0 || idx >= currentRow.length) idx = 0;
    // If the selected tile has no letter, try to color the last non-empty editable tile
    if (currentRow[idx].letter.isEmpty) {
      final prev = findLastEditableNonEmptyIndex();
      if (prev != null) idx = prev;
    }
    // If still no letter to color, do nothing
    if (currentRow[idx].letter.isEmpty) return;
    if (_isPrefixLockedIndex(idx)) return;
    // Toggle: requesting the same color again reverts to black
    final current = currentRow[idx];
    final nextColor = (current.feedback == feedback)
        ? TileFeedback.black
        : feedback;
    // Apply feedback without moving selection so typing continues to the next tile
    _updateTile(idx, feedback: nextColor);
    state = state.copyWith(currentRowFeedbackTouched: true);
  }

  // Reset all feedback colors in the current input row to black while preserving letters.
  void resetCurrentRowFeedbackToBlack() {
    if (state.grid.isEmpty) return;
    final rows = List<List<SolverTile>>.from(state.grid.map((r) => List.of(r)));
    final current = List<SolverTile>.from(rows.removeLast());
    for (int i = 0; i < current.length; i++) {
      if (_isPrefixLockedIndex(i)) {
        // Preserve locked prefix tile's feedback (typically green)
        continue;
      }
      current[i] = current[i].copyWith(feedback: TileFeedback.black);
    }
    rows.add(current);
    state = state.copyWith(
      grid: rows,
      // Keep selection as-is; mark that feedback was touched
      currentRowFeedbackTouched: true,
      errorMessage: null,
    );
  }

  // Apply a filler word: set all letters and mark all tiles black; store current greens
  void applyFillerWord(String word) {
    final rows = List<List<SolverTile>>.from(state.grid.map((r) => List.of(r)));
    if (rows.isEmpty) return;
    final currentRow = List<SolverTile>.from(rows.removeLast());

    final Map<int, String> greens = {};
    for (int i = 0; i < currentRow.length && i < word.length; i++) {
      if (currentRow[i].feedback == TileFeedback.green &&
          currentRow[i].letter.isNotEmpty) {
        greens[i] = currentRow[i].letter;
      }
    }

    final List<SolverTile> updated = List.from(currentRow);
    for (int i = 0; i < updated.length; i++) {
      final ch = i < word.length ? word[i].toLowerCase() : '';
      updated[i] = updated[i].copyWith(
        letter: ch,
        feedback: TileFeedback.black,
      );
    }

    rows.add(updated);
    state = state.copyWith(
      grid: rows,
      pendingGreenLocks: greens.isEmpty ? null : greens,
      currentRowFeedbackTouched: true,
      errorMessage: null,
      // Unlock prefix for this row to allow changing its color when using a filler
      unlockPrefixThisRow: true,
    );
  }

  void selectTile(int colIndex) {
    state = state.copyWith(selectedIndex: colIndex);
  }

  void resetGame() {
    // New game resets everything, including prefix; enforce defaults from Issue #14
    final newConfig = SolverConfig(
      wordLength: 5,
      prefix: null,
      dictionary: state.config.dictionary,
      autoCopyOnSelect: state.config.autoCopyOnSelect,
    );
    final newRow = List.generate(
      5,
      (_) => const SolverTile(letter: '', feedback: TileFeedback.black),
    );
    state = state.copyWith(
      config: newConfig,
      grid: [newRow],
      lastResponse: null,
      errorMessage: null,
      isLoading: false,
      selectedIndex: 0,
      currentRowFeedbackTouched: false,
      pendingGreenLocks: null,
      unlockPrefixThisRow: false,
    );
  }

  // Mark the current row as a confirmed win: set all tiles to green.
  // If a single recommendation word is provided and the current row is incomplete,
  // fill the row with that word before setting greens.
  void confirmWin([String? word]) {
    if (state.grid.isEmpty) return;
    final rows = List<List<SolverTile>>.from(state.grid.map((r) => List.of(r)));
    final currentRow = List<SolverTile>.from(rows.removeLast());

    List<SolverTile> target = List<SolverTile>.from(currentRow);
    // Optionally fill letters from provided word when length matches
    if (word != null && word.length == target.length) {
      for (int i = 0; i < target.length; i++) {
        final ch = word[i].toLowerCase();
        target[i] = target[i].copyWith(letter: ch);
      }
    }
    // Set all feedback to green
    for (int i = 0; i < target.length; i++) {
      target[i] = target[i].copyWith(feedback: TileFeedback.green);
    }

    rows.add(target);
    state = state.copyWith(
      grid: rows,
      selectedIndex: target.length - 1,
      errorMessage: null,
    );
  }

  // Validate that the current row's word is consistent with all previous
  // feedback (history) and constraints. This does not mutate state or set
  // loading flags. Returns false if the row is incomplete.
  Future<bool> canConfirmWinWithCurrentRowWord() async {
    if (state.grid.isEmpty || state.grid.last.isEmpty) return false;
    final currentRow = state.grid.last;
    final isComplete = !currentRow.any((t) => t.letter.isEmpty);
    if (!isComplete) return false;
    final guess = currentRow.map((t) => t.letter).join();

    // Fast path: if we already have remaining candidates, check membership
    final existingRemaining = state.lastResponse?.remainingWords;
    if (existingRemaining != null && existingRemaining.isNotEmpty) {
      return existingRemaining.contains(guess);
    }

    // Otherwise, compute candidates based on prior history only (exclude current row)
    try {
      final history = _toHistory();
      final response = await repository.calculateNextMove(
        config: state.config,
        history: history,
      );
      return response.remainingWords.contains(guess);
    } catch (_) {
      return false;
    }
  }

  // Optional: explicit methods for docs behaviour
  void onTileTap(int index) => toggleFeedback(index);
  void onTileLongPress(int index) => toggleFeedback(index);

  void _updateTile(int colIndex, {String? letter, TileFeedback? feedback}) {
    final rows = List<List<SolverTile>>.from(state.grid.map((r) => List.of(r)));
    final row = rows.removeLast();
    final updated = List<SolverTile>.from(row);
    final t = updated[colIndex];
    updated[colIndex] = t.copyWith(
      letter: letter ?? t.letter,
      feedback: feedback ?? t.feedback,
    );
    rows.add(updated);
    state = state.copyWith(grid: rows, errorMessage: null);
  }

  List<HistoryEntry> _toHistory() {
    // All rows except the last (current input) are history
    final historyRows = state.grid.length > 1
        ? state.grid.sublist(0, state.grid.length - 1)
        : <List<SolverTile>>[];
    return historyRows
        .map((row) {
          final guess = row
              .map((t) => t.letter.isEmpty ? '_' : t.letter)
              .join();
          final feedback = row.map((t) {
            switch (t.feedback) {
              case TileFeedback.green:
                return 'g';
              case TileFeedback.yellow:
                return 'y';
              case TileFeedback.black:
                return 'b';
            }
          }).join();
          return HistoryEntry(guess: guess, feedback: feedback);
        })
        .toList(growable: false);
  }

  Future<void> requestRecommendations() async {
    final currentRow = state.grid.last;
    final prefix = state.config.prefix;
    bool usedCurrentRowAsGuess = false;

    // Build history ignoring an incomplete current row (allow recommendations anytime)
    final preSubmitHistory = _toHistory();
    List<HistoryEntry> newHistory = preSubmitHistory;

    // Simplified rule: on the first submission, if the first tile is green and
    // a letter is present, that letter is the prefix. This applies even when the
    // row is incomplete.
    if ((state.config.prefix ?? '').isEmpty && preSubmitHistory.isEmpty) {
      if (currentRow.isNotEmpty) {
        final first = currentRow.first;
        if (first.feedback == TileFeedback.green && first.letter.isNotEmpty) {
          setPrefix(first.letter.toLowerCase());
        }
      }
    }

    final isRowComplete = !currentRow.any((t) => t.letter.isEmpty);
    if (isRowComplete) {
      final guess = currentRow.map((t) => t.letter).join();
      final feedback = currentRow.map((t) {
        switch (t.feedback) {
          case TileFeedback.green:
            return 'g';
          case TileFeedback.yellow:
            return 'y';
          case TileFeedback.black:
            return 'b';
        }
      }).join();
      newHistory = [
        ...newHistory,
        HistoryEntry(guess: guess, feedback: feedback),
      ];
      usedCurrentRowAsGuess = true;

      // prefix deduction handled above for both incomplete and complete rows
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await repository.calculateNextMove(
        config: state.config,
        history: newHistory,
      );

      // Append a new empty input row only if we consumed the current row as a guess
      List<List<SolverTile>> updatedGrid = state.grid;
      if (usedCurrentRowAsGuess) {
        final newRow = List.generate(
          state.config.wordLength,
          (_) => const SolverTile(letter: '', feedback: TileFeedback.black),
        );
        // Carry forward greens: prefer pending locks captured before filler; else use last row greens
        final pending = state.pendingGreenLocks;
        if (pending != null && pending.isNotEmpty) {
          for (final entry in pending.entries) {
            final i = entry.key;
            if (i >= 0 && i < newRow.length) {
              newRow[i] = newRow[i].copyWith(
                letter: entry.value,
                feedback: TileFeedback.green,
              );
            }
          }
        } else {
          final lastRow = state.grid.last;
          for (int i = 0; i < lastRow.length && i < newRow.length; i++) {
            if (lastRow[i].feedback == TileFeedback.green) {
              newRow[i] = newRow[i].copyWith(
                letter: lastRow[i].letter,
                feedback: TileFeedback.green,
              );
            }
          }
        }
        // Auto-populate prefix on the new row if present
        if (prefix != null && prefix.isNotEmpty) {
          newRow[0] = newRow[0].copyWith(
            letter: prefix[0].toLowerCase(),
            feedback: TileFeedback.green,
          );
        }
        updatedGrid = [...state.grid, newRow];
      }

      state = state.copyWith(
        lastResponse: response,
        isLoading: false,
        grid: updatedGrid,
        errorMessage: null,
        currentRowFeedbackTouched: false,
        pendingGreenLocks: null,
        // Once we move to the next step/row, relock prefix if present
        unlockPrefixThisRow: false,
        // After consuming a row and appending a new one, start selection at first tile
        selectedIndex: usedCurrentRowAsGuess ? 0 : state.selectedIndex,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get recommendations',
      );
    }
  }
}

final solverRepositoryProvider = Provider<SolverRepository>((ref) {
  return SolverRepository();
});

final solverControllerProvider =
    StateNotifierProvider<SolverController, SolverUiState>((ref) {
      final repo = ref.watch(solverRepositoryProvider);
      return SolverController(repository: repo);
    });

// Shared FocusNode for global grid keyboard handling so other widgets can
// restore focus after their own inputs are used.
final gridKeyboardFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(skipTraversal: true);
  ref.onDispose(node.dispose);
  return node;
});

// Tracks whether any tile TextField within the grid currently has focus.
// Used to gate screen-level keyboard handling to avoid duplicate processing
// when a tile is actively focused for typing.
final tileFocusActiveProvider = StateProvider<bool>((ref) => false);
