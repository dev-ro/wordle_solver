import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wordle_solver/screens/home_screen.dart';
import 'package:wordle_solver/state/solver_state.dart';
import 'package:wordle_solver/models/solver_models.dart';
import 'package:wordle_solver/repositories/solver_repository.dart';

void main() {
  testWidgets('renders HomeScreen and title', (WidgetTester tester) async {
    // Override repository to avoid Firebase initialization in tests
    await tester.pumpWidget(ProviderScope(
      overrides: [
        solverRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));

    // AppBar title
    expect(find.text('Wordle Solver'), findsOneWidget);

    // Length slider exists
    expect(find.byType(Slider), findsOneWidget);
  });
}

class _FakeRepository implements SolverRepository {
  @override
  Future<SolverResponse> calculateNextMove({
    required SolverConfig config,
    required List<HistoryEntry> history,
  }) async {
    return SolverResponse(
      recommendations: const [],
      remainingWords: const [],
      remainingCount: 0,
      variablePositions: const {},
      fillerSuggestions: const [],
      guessCount: 1,
    );
  }
}


