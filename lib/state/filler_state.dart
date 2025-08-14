import 'dart:async';

// Removed foundation import; widgets provides @immutable in this file
import 'package:flutter/widgets.dart';
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
  String _lastAutoSuggestLetters = '';
  int _manualSearchRequestId = 0; // increases with each setQuery call

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

    // Invalidate any in-flight manual searches and capture this call's id
    final int requestIdForThisCall = ++_manualSearchRequestId;

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(manualResults: [], isLoadingManual: false);
      return;
    }
    // Robust guard: ignore queries shorter than 3 letters to avoid noisy results
    if (trimmed.length < 3) {
      state = state.copyWith(manualResults: [], isLoadingManual: false);
      return;
    }

    state = state.copyWith(isLoadingManual: true);
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _performManualSearch(
        query: trimmed,
        config: config,
        requestId: requestIdForThisCall,
      );
    });
  }

  Future<void> _performManualSearch({
    required String query,
    required SolverConfig config,
    required int requestId,
  }) async {
    try {
      final all = await service.loadDictionary(config.dictionary);
      final filtered = all
          .where((w) => w.length == config.wordLength)
          .toList(growable: false);
      final results = service.findWordsWithLetters(filtered, query, n: 30);

      if (requestId == _manualSearchRequestId) {
        state = state.copyWith(manualResults: results);
      }
    } catch (_) {
      // Swallow errors to avoid leaving UI in loading state
    } finally {
      if (requestId == _manualSearchRequestId) {
        state = state.copyWith(isLoadingManual: false);
      }
    }
  }

  Future<void> computeAutoSuggest({
    required SolverConfig config,
    required List<String> remainingCandidates,
    Set<String>? omitLetters,
  }) async {
    final positions = service.findVariableLetterPositions(remainingCandidates);
    var letters = service.collectVariableLetters(positions);
    if (omitLetters != null && omitLetters.isNotEmpty) {
      final filtered =
          letters.split('').where((ch) => !omitLetters.contains(ch)).toList()
            ..sort();
      letters = filtered.join();
    }
    _lastAutoSuggestLetters = letters;
    final all = await service.loadDictionary(config.dictionary);
    // Filler auto-suggest ignores prefix and previous guesses; only match length
    final filteredWords = all
        .where((w) => w.length == config.wordLength)
        .toList(growable: false);
    final results = service.findWordsWithLetters(filteredWords, letters, n: 9);
    state = state.copyWith(autoSuggestResults: results);
  }

  String get lastAutoSuggestLetters => _lastAutoSuggestLetters;
}

final fillerWordsServiceProvider = Provider<FillerWordsService>((ref) {
  return FillerWordsService();
});

final fillerControllerProvider =
    StateNotifierProvider<FillerController, FillerUiState>((ref) {
      final svc = ref.watch(fillerWordsServiceProvider);
      return FillerController(service: svc);
    });

// Controller for the manual search TextField that mirrors the query in state
final fillerQueryTextControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController(
        text: ref.read(fillerControllerProvider).query,
      );
      // Keep controller text in sync when query changes programmatically
      ref.listen<FillerUiState>(fillerControllerProvider, (prev, next) {
        if (controller.text != next.query) {
          controller.text = next.query;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      });
      ref.onDispose(controller.dispose);
      return controller;
    });
