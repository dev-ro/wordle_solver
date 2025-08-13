import 'package:flutter_test/flutter_test.dart';
import 'package:wordle_solver/models/solver_models.dart';
import 'package:wordle_solver/state/solver_state.dart';
import 'package:wordle_solver/repositories/solver_repository.dart';

class _FakeRepo extends SolverRepository {
  @override
  Future<SolverResponse> calculateNextMove({
    required SolverConfig config,
    required List<HistoryEntry> history,
  }) async {
    // Minimal deterministic response to satisfy controller expectations
    return SolverResponse(
      recommendations: const [],
      remainingWords: const [],
      remainingCount: 0,
      variablePositions: const {},
      fillerSuggestions: const [],
      guessCount: history.length + 1,
    );
  }
}

void main() {
  group('Issue #63 behavior', () {
    test('Arrow navigation may land on green tiles', () async {
      final ctrl = SolverController(repository: _FakeRepo());

      // Build a row with a green tile at index 1
      final row = <SolverTile>[
        const SolverTile(letter: 'a', feedback: TileFeedback.black),
        const SolverTile(letter: 'b', feedback: TileFeedback.green),
        const SolverTile(letter: 'c', feedback: TileFeedback.black),
        const SolverTile(letter: 'd', feedback: TileFeedback.black),
        const SolverTile(letter: 'e', feedback: TileFeedback.black),
      ];
      ctrl.state = ctrl.state.copyWith(grid: [row], selectedIndex: 2);

      ctrl.moveSelectionLeft();
      expect(ctrl.state.selectedIndex, 1);

      ctrl.moveSelectionRight();
      expect(ctrl.state.selectedIndex, 2);
    });

    test(
      'Length change fully resets and suppresses carry-forward once',
      () async {
        final ctrl = SolverController(repository: _FakeRepo());
        ctrl.setWordLength(7);

        expect(ctrl.state.config.wordLength, 7);
        expect(ctrl.state.config.prefix, isNull);
        expect(ctrl.state.pendingGreenLocks, isNull);
        expect(ctrl.state.grid.length, 1);
        expect(ctrl.state.grid.first.length, 7);
        expect(ctrl.state.suppressCarryForwardOnce, isTrue);
      },
    );

    test(
      'Dictionary change fully resets and suppresses carry-forward once',
      () async {
        final ctrl = SolverController(repository: _FakeRepo());
        ctrl.setDictionary('spanish.json');

        expect(ctrl.state.config.dictionary, 'spanish.json');
        expect(ctrl.state.config.prefix, isNull);
        expect(ctrl.state.pendingGreenLocks, isNull);
        expect(ctrl.state.grid.length, 1);
        expect(ctrl.state.grid.first.length, ctrl.state.config.wordLength);
        expect(ctrl.state.suppressCarryForwardOnce, isTrue);
      },
    );

    test('Reset game clears board and memory', () async {
      final ctrl = SolverController(repository: _FakeRepo());
      ctrl.resetGame();

      expect(ctrl.state.config.wordLength, 5);
      expect(ctrl.state.config.prefix, isNull);
      expect(ctrl.state.grid.length, 1);
      expect(ctrl.state.grid.first.length, 5);
      expect(ctrl.state.pendingGreenLocks, isNull);
      expect(ctrl.state.suppressCarryForwardOnce, isTrue);
    });

    test('Confirm win triggers fresh board for a new game', () async {
      final ctrl = SolverController(repository: _FakeRepo());
      // Fill current row to allow confirm
      final row = <SolverTile>[
        const SolverTile(letter: 'h', feedback: TileFeedback.black),
        const SolverTile(letter: 'a', feedback: TileFeedback.black),
        const SolverTile(letter: 'n', feedback: TileFeedback.black),
        const SolverTile(letter: 'k', feedback: TileFeedback.black),
        const SolverTile(letter: 'y', feedback: TileFeedback.black),
      ];
      ctrl.state = ctrl.state.copyWith(grid: [row]);

      ctrl.confirmWin();
      // Allow microtask in confirmWin to run
      await Future<void>.delayed(Duration.zero);

      expect(ctrl.state.grid.length, 1);
      expect(ctrl.state.grid.first.any((t) => t.letter.isNotEmpty), isFalse);
      expect(ctrl.state.config.prefix, isNull);
      expect(ctrl.state.suppressCarryForwardOnce, isTrue);
    });
  });
}
