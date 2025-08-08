import 'package:cloud_functions/cloud_functions.dart';

import '../models/solver_models.dart';

class SolverRepository {
  final FirebaseFunctions _functions;

  SolverRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  Future<SolverResponse> calculateNextMove({
    required SolverConfig config,
    required List<HistoryEntry> history,
  }) async {
    final callable = _functions.httpsCallable('calculate_next_move');
    final payload = {
      'config': config.toMap(),
      'history': history.map((h) => h.toMap()).toList(),
    };

    final HttpsCallableResult response = await callable.call(payload);
    final data = (response.data as Map).cast<String, dynamic>();
    return SolverResponse.fromMap(data);
  }
}
