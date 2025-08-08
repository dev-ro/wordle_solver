import 'package:flutter/material.dart';

import '../../models/solver_models.dart';
import '../common/aurora.dart';

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
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (response == null) ...[
          Text(
            'Tap Recommend to get suggestions',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ] else if (response!.recommendations.isEmpty) ...[
          Text(
            'No recommendations yet. Try adjusting input or press Recommend again.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          LayoutBuilder(builder: (context, c) {
            final recs = [...response!.recommendations];
            recs.sort((a, b) => b.score.compareTo(a.score));
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: recs.length.clamp(0, 9),
              itemBuilder: (context, index) {
                final r = recs[index];
                return AuroraHoverTile(
                  emphasize: index == 0,
                  onTap: () => onSelectWord(r.word),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        r.word.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.score.toStringAsFixed(2),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 16),
          AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Remaining Words (${response!.remainingCount})',
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: response!.remainingWords.take(50).map((w) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                         decoration: BoxDecoration(
                           color: const Color(0xFF15151A).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Text(
                          w,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Filler suggestions are intentionally not auto-shown here.
        ],
      ],
    );
  }
}
