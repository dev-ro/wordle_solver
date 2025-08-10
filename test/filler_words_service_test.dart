import 'package:flutter_test/flutter_test.dart';

import 'package:wordle_solver/services/filler_words_service.dart';

void main() {
  test('findVariableLetterPositions and collectVariableLetters', () {
    final svc = FillerWordsService();
    final words = ['gaming', 'vaping'];
    final pos = svc.findVariableLetterPositions(words);
    expect(pos.isNotEmpty, true);
    final letters = svc.collectVariableLetters(pos);
    // contains at least these varying letters
    expect(letters.contains('g'), true);
    expect(letters.contains('v'), true);
  });

  test('findWordsWithLetters scores and sorts', () {
    final svc = FillerWordsService();
    final words = ['abcde', 'bcdef', 'zzzzz'];
    final results = svc.findWordsWithLetters(words, 'abz', n: 3);
    // 'abcde' matches {a,b} -> 2, 'bcdef' matches {b} -> 1, 'zzzzz' matches {z} -> 1 (tie order may vary but first has highest)
    expect(results.first.key, 'abcde');
    expect(results.first.value, 2);
  });
}
