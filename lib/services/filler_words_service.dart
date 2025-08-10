import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class FillerWordsService {
  FillerWordsService();

  final Map<String, List<String>> _dictionaryCache = {};

  Future<List<String>> loadDictionary(String filename) async {
    if (_dictionaryCache.containsKey(filename)) {
      return _dictionaryCache[filename]!;
    }
    final raw = await rootBundle.loadString('assets/words/$filename');
    final List<dynamic> jsonList = json.decode(raw) as List<dynamic>;
    final words = jsonList
        .map((e) => e.toString().toLowerCase())
        .toList(growable: false);
    _dictionaryCache[filename] = words;
    return words;
  }

  Map<int, Set<String>> findVariableLetterPositions(List<String> words) {
    if (words.isEmpty) return {};
    final int length = words.first.length;
    final Map<int, Set<String>> variablePositions = {
      for (int i = 0; i < length; i++) i: <String>{},
    };
    for (final w in words) {
      for (int i = 0; i < w.length && i < length; i++) {
        variablePositions[i]!.add(w[i]);
      }
    }
    // Keep only positions with variance > 1
    return Map.fromEntries(
      variablePositions.entries.where((e) => e.value.length > 1),
    );
  }

  String collectVariableLetters(Map<int, Set<String>> positions) {
    final Set<String> letters = {};
    for (final s in positions.values) {
      letters.addAll(s);
    }
    final sorted = letters.toList()..sort();
    return sorted.join();
  }

  List<MapEntry<String, int>> findWordsWithLetters(
    List<String> words,
    String letters, {
    int n = 30,
  }) {
    final Set<String> letterSet = letters.toLowerCase().split('').toSet();
    if (letterSet.isEmpty) return const [];

    final scored = <MapEntry<String, int>>[];
    for (final w in words) {
      int score = 0;
      for (final ch in letterSet) {
        if (w.contains(ch)) score += 1;
      }
      if (score > 0) {
        scored.add(MapEntry(w, score));
      }
    }
    // Sort by score desc, tie-break by alpha for stability
    scored.sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      if (cmp != 0) return cmp;
      return a.key.compareTo(b.key);
    });
    if (scored.length > n) {
      return scored.sublist(0, n);
    }
    return scored;
  }
}
