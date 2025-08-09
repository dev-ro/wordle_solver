import 'package:flutter/foundation.dart';

@immutable
class SolverConfig {
  final int wordLength;
  final String? prefix;
  final String dictionary; // e.g., 'english.json'
  final bool
  autoCopyOnSelect; // whether tapping a recommendation copies it to clipboard

  const SolverConfig({
    required this.wordLength,
    this.prefix,
    required this.dictionary,
    this.autoCopyOnSelect = true,
  });

  SolverConfig copyWith({
    int? wordLength,
    String? prefix,
    String? dictionary,
    bool? autoCopyOnSelect,
  }) {
    return SolverConfig(
      wordLength: wordLength ?? this.wordLength,
      prefix: prefix ?? this.prefix,
      dictionary: dictionary ?? this.dictionary,
      autoCopyOnSelect: autoCopyOnSelect ?? this.autoCopyOnSelect,
    );
  }

  Map<String, dynamic> toMap() => {
    'wordLength': wordLength,
    'prefix': prefix,
    'dictionary': dictionary,
    'autoCopyOnSelect': autoCopyOnSelect,
  };
}

@immutable
class HistoryEntry {
  final String guess; // e.g., 'crane'
  final String feedback; // e.g., 'bbbyg' where g=green, y=yellow, b=black

  const HistoryEntry({required this.guess, required this.feedback})
    : assert(guess.length == feedback.length);

  Map<String, dynamic> toMap() => {'guess': guess, 'feedback': feedback};
}

@immutable
class SolverRecommendation {
  final String word;
  final double score;

  const SolverRecommendation({required this.word, required this.score});

  factory SolverRecommendation.fromMap(Map<String, dynamic> map) {
    return SolverRecommendation(
      word: map['word'] as String,
      score: (map['score'] as num).toDouble(),
    );
  }
}

@immutable
class SolverResponse {
  final List<SolverRecommendation> recommendations;
  final List<String> remainingWords;
  final int remainingCount;
  final Map<int, List<String>> variablePositions;
  final List<String> fillerSuggestions;
  final int guessCount;

  const SolverResponse({
    required this.recommendations,
    required this.remainingWords,
    required this.remainingCount,
    required this.variablePositions,
    required this.fillerSuggestions,
    required this.guessCount,
  });

  factory SolverResponse.fromMap(Map<String, dynamic> map) {
    final recs = (map['recommendations'] as List<dynamic>? ?? [])
        .map(
          (e) =>
              SolverRecommendation.fromMap((e as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);

    final remainingWords = (map['remainingWords'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(growable: false);

    final varPosRaw = (map['variablePositions'] as Map? ?? {})
        .cast<String, dynamic>();
    final variablePositions = <int, List<String>>{};
    for (final entry in varPosRaw.entries) {
      final key = int.tryParse(entry.key);
      if (key != null) {
        variablePositions[key] = (entry.value as List<dynamic>)
            .map((e) => e.toString())
            .toList(growable: false);
      }
    }

    return SolverResponse(
      recommendations: recs,
      remainingWords: remainingWords,
      remainingCount: (map['remainingCount'] as num? ?? 0).toInt(),
      variablePositions: variablePositions,
      fillerSuggestions: (map['fillerSuggestions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(growable: false),
      guessCount: (map['guessCount'] as num? ?? 1).toInt(),
    );
  }
}
