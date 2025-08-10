import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/solver_models.dart';
import '../services/filler_words_service.dart';

@immutable
class FillerUiState {
  final String query; // e.g., "bhptw"
  final List<MapEntry<String, int>> manualResults; // scored results
  final List<MapEntry<String, int>> autoSuggestResults; // scored results
  final bool isLoadingManual;

  const FillerUiState({
    required this.query,
    required this.manualResults,
    required this.autoSuggestResults,
    required this.isLoadingManual,
  });

  FillerUiState copyWith({
    String? query,
    List<MapEntry<String, int>>? manualResults,
    List<MapEntry<String, int>>? autoSuggestResults,
    bool? isLoadingManual,
  }) {
    return FillerUiState(
      query: query ?? this.query,
      manualResults: manualResults ?? this.manualResults,
      autoSuggestResults: autoSuggestResults ?? this.autoSuggestResults,
      isLoadingManual: isLoadingManual ?? this.isLoadingManual,
    );
  }
}

class FillerController extends StateNotifier<FillerUiState> {
  final FillerWordsService service;
  Timer? _debounce;

  FillerController({required this.service})
    : super(
        const FillerUiState(
          query: '',
          manualResults: [],
          autoSuggestResults: [],
          isLoadingManual: false,
        ),
      );

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setQuery(String query, {required SolverConfig config}) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(manualResults: [], isLoadingManual: false);
      return;
    }
    state = state.copyWith(isLoadingManual: true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final all = await service.loadDictionary(config.dictionary);
      // Filler manual search ignores prefix and previous guesses; only match length
      final filtered = all
          .where((w) => w.length == config.wordLength)
          .toList(growable: false);
      final results = service.findWordsWithLetters(filtered, query, n: 30);
      state = state.copyWith(manualResults: results, isLoadingManual: false);
    });
  }

  Future<void> computeAutoSuggest({
    required SolverConfig config,
    required List<String> remainingCandidates,
  }) async {
    final positions = service.findVariableLetterPositions(remainingCandidates);
    final letters = service.collectVariableLetters(positions);
    final all = await service.loadDictionary(config.dictionary);
    // Filler auto-suggest ignores prefix and previous guesses; only match length
    final filtered = all
        .where((w) => w.length == config.wordLength)
        .toList(growable: false);
    final results = service.findWordsWithLetters(filtered, letters, n: 9);
    state = state.copyWith(autoSuggestResults: results);
  }
}

final fillerWordsServiceProvider = Provider<FillerWordsService>((ref) {
  return FillerWordsService();
});

final fillerControllerProvider =
    StateNotifierProvider<FillerController, FillerUiState>((ref) {
      final svc = ref.watch(fillerWordsServiceProvider);
      return FillerController(service: svc);
    });
