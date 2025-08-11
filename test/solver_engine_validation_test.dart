import 'package:flutter_test/flutter_test.dart';

import 'package:wordle_solver/solver/solver_engine.dart';

void main() {
  group('computeNextMove input validation', () {
    final dictionary = ['crane', 'slate', 'stare', 'raise', 'cigar'];

    test('throws on mismatched guess/feedback lengths', () {
      expect(
        () => computeNextMove(
          dictionary: dictionary,
          wordLength: 5,
          prefix: null,
          history: const [
            {'guess': 'crane', 'feedback': 'ggg'}, // bad length
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid feedback character', () {
      expect(
        () => computeNextMove(
          dictionary: dictionary,
          wordLength: 5,
          prefix: null,
          history: const [
            {'guess': 'crane', 'feedback': 'gbxgy'}, // 'x' invalid
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid history and returns result', () {
      final result = computeNextMove(
        dictionary: dictionary,
        wordLength: 5,
        prefix: null,
        history: const [
          {'guess': 'crane', 'feedback': 'bbbbb'},
        ],
      );
      expect(result['remainingCount'], isNonZero);
      expect(result['recommendations'], isA<List<dynamic>>());
    });
  });
}
