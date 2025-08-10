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
            'Tap Submit to get suggestions',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ] else if (response!.recommendations.isEmpty) ...[
          Text(
            'No recommendations yet. Try adjusting input or press Submit again.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          LayoutBuilder(
            builder: (context, c) {
              final recs = [...response!.recommendations];
              recs.sort((a, b) => b.score.compareTo(a.score));

              // Fixed 3x3 grid, up to 9 items, rectangular tiles
              final topCount = recs.length.clamp(0, 9);

              // Compute top 3 unique scores
              final uniqueScores = <double>[];
              for (final r in recs) {
                if (!uniqueScores.contains(r.score)) {
                  uniqueScores.add(r.score);
                }
                if (uniqueScores.length == 3) break;
              }

              Color borderColorFor(double score) {
                final idx = uniqueScores.indexOf(score);
                if (idx == 0) return const Color(0xFFFFD700); // gold
                if (idx == 1) return const Color(0xFFC0C0C0); // silver
                if (idx == 2) return const Color(0xFFCD7F32); // bronze
                return Colors.white24; // default
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: topCount,
                itemBuilder: (context, index) {
                  final r = recs[index];
                  return AuroraHoverTile(
                    emphasize: index == 0,
                    onTap: () => onSelectWord(r.word),
                    borderColorOverride: borderColorFor(r.score),
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
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.score.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          AuroraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Remaining Words (${response!.remainingCount})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: response!.remainingWords.take(50).map((w) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15151A).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Text(
                          w,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
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
