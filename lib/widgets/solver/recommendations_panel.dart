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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recommendations',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (response == null || response!.recommendations.isEmpty) ...[
          Text(
            'Tap Recommend to get suggestions',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Wrap(
            alignment: WrapAlignment.center,
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
          const SizedBox(height: 12),
          Text(
            'Remaining: ${response!.remainingCount}',
            style: theme.textTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: response!.remainingWords
                .take(50)
                .map((w) => Chip(label: Text(w)))
                .toList(),
          ),
          if (response!.fillerSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Filler suggestions',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: response!.fillerSuggestions
                  .map(
                    (w) => InputChip(
                      label: Text(w),
                      onPressed: () => onSelectWord(w),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ],
    );
  }
}
