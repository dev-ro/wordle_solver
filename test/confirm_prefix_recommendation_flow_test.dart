import 'package:flutter_test/flutter_test.dart';

import 'package:wordle_solver/models/solver_models.dart';
import 'package:wordle_solver/repositories/solver_repository.dart';
import 'package:wordle_solver/state/solver_state.dart';

class _FakeRepo extends SolverRepository {
  @override
  Future<SolverResponse> calculateNextMove({
    required SolverConfig config,
    required List<HistoryEntry> history,
  }) async {
    // Minimal stub: return a static set of remaining words so UI gating can use it
    return SolverResponse(
      recommendations: const [],
      remainingWords: const ['arose', 'align', 'alien'],
      remainingCount: 3,
      variablePositions: const {},
      fillerSuggestions: const [],
      guessCount: (history.length + 1),
    );
  }
}

void main() {
  test(
    'applyWordToCurrentRow keeps row complete with prefix across selections',
    () async {
      final ctrl = SolverController(repository: _FakeRepo());

      // Ensure 5-letter board and set prefix 'a'
      ctrl.setWordLength(5);
      ctrl.setPrefix('a');

      // First selection fills the row
      ctrl.applyWordToCurrentRow('arose');
      final firstRow = ctrl.state.grid.last;
      expect(firstRow.any((t) => t.letter.isEmpty), false);
      expect(firstRow.first.letter, 'a');

      // Second selection should keep the row complete
      ctrl.applyWordToCurrentRow('align');
      final secondRow = ctrl.state.grid.last;
      expect(secondRow.any((t) => t.letter.isEmpty), false);
      expect(secondRow.map((t) => t.letter).join(), 'align');

      // Confirm gating precondition (row complete) remains true
      final isComplete =
          secondRow.isNotEmpty && !secondRow.any((t) => t.letter.isEmpty);
      expect(isComplete, true);
    },
  );

  test('canConfirm accepts words present in recommendations', () async {
    final ctrl = SolverController(repository: _FakeRepo());
    ctrl.setWordLength(5);
    ctrl.setPrefix('a');
    // Simulate a response where ALIGN is recommended/remaining
    await ctrl.requestRecommendationsWithoutConsuming();
    ctrl.applyWordToCurrentRow('align');
    final ok = await ctrl.canConfirmWinWithCurrentRowWord();
    expect(ok, true);
  });
}
