import 'package:flutter/foundation.dart';
import '../models/solver_models.dart';
import '../services/dictionary_service.dart';
import '../solver/solver_engine.dart' as engine;

class SolverRepository {
  final DictionaryService _dictionaryService;

  SolverRepository({DictionaryService? dictionaryService})
    : _dictionaryService = dictionaryService ?? DictionaryService();

  Future<SolverResponse> calculateNextMove({
    required SolverConfig config,
    required List<HistoryEntry> history,
  }) async {
    final dictionary = await _dictionaryService.loadDictionary(
      config.dictionary,
    );

    // Prepare payload for background compute
    final payload = <String, dynamic>{
      'dictionary': dictionary,
      'wordLength': config.wordLength,
      'prefix': config.prefix,
      'history': [
        for (final h in history) {'guess': h.guess, 'feedback': h.feedback},
      ],
    };

    final result = await compute(_computeInBackground, payload);
    return SolverResponse.fromMap(result.cast<String, dynamic>());
  }
}

Map<String, dynamic> _computeInBackground(Map<String, dynamic> payload) {
  final dictionary = (payload['dictionary'] as List).cast<String>();
  final wordLength = payload['wordLength'] as int;
  final prefix = payload['prefix'] as String?;
  final history = (payload['history'] as List)
      .map((e) => (e as Map).cast<String, String>())
      .toList(growable: false);

  return engine.computeNextMove(
    dictionary: dictionary,
    wordLength: wordLength,
    prefix: prefix,
    history: history,
  );
}
