import 'package:flutter/material.dart';

import '../../models/solver_models.dart';

class RecommendationsPanel extends StatelessWidget {
  final SolverResponse? response;
  final ValueChanged<String> onSelectWord;

  const RecommendationsPanel({
    super.key,
    required this.response,
    required this.onSelectWord,
  });

  @override
  Widget build(BuildContext context) {
    if (response == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recommendations (${response!.recommendations.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: response!.recommendations
              .map(
                (r) => ActionChip(
                  label: Text('${r.word} (${r.score.toStringAsFixed(1)})'),
                  onPressed: () => onSelectWord(r.word),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Remaining: ${response!.remainingCount}', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: response!.remainingWords
                .take(50)
                .map((w) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(label: Text(w)),
                    ))
                .toList(),
          ),
        ),
        if (response!.fillerSuggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Filler suggestions', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: response!.fillerSuggestions
                .map((w) => InputChip(
                      label: Text(w),
                      onPressed: () => onSelectWord(w),
                    ))
                .toList(),
          ),
        ]
      ],
    );
  }
}


