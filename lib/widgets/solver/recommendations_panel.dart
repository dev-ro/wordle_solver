import 'package:flutter/material.dart';

import '../../models/solver_models.dart';
import '../common/aurora.dart';

class RecommendationsPanel extends StatelessWidget {
  final SolverResponse? response;
  final ValueChanged<String> onSelectWord;
  final bool isLoading;

  const RecommendationsPanel({
    super.key,
    required this.response,
    required this.onSelectWord,
    this.isLoading = false,
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
        if (isLoading) ...[
          const SizedBox(height: 8),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading recommendations…',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ] else if (response == null) ...[
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

              Gradient? gradientFor(double score) {
                final idx = uniqueScores.indexOf(score);
                if (idx == 0) {
                  // Gold metallic gradient
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFA57C00),
                      Color(0xFFFFD700),
                      Color(0xFFFFF1B5),
                      Color(0xFFA57C00),
                    ],
                  );
                }
                if (idx == 1) {
                  // Silver metallic gradient
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8A8A8A),
                      Color(0xFFC0C0C0),
                      Color(0xFFEDEDED),
                      Color(0xFF8A8A8A),
                    ],
                  );
                }
                if (idx == 2) {
                  // Bronze metallic gradient
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6E3F1F),
                      Color(0xFFCD7F32),
                      Color(0xFFE8C29B),
                      Color(0xFF6E3F1F),
                    ],
                  );
                }
                return null;
              }

              // Compute a responsive childAspectRatio to ensure a flatter, horizontal rectangle.
              // Derive from available width instead of hardcoded screen breakpoints.
              const columns = 3;
              const spacing = 10.0;
              final availableWidth = c.maxWidth;
              final tileWidth =
                  (availableWidth - (columns - 1) * spacing) / columns;
              // Compute target height from content to avoid clipping at larger text scales
              final textScaler = MediaQuery.textScalerOf(context);
              const wordFontSize = 15.0;
              const scoreFontSize = 11.0;
              const interTextSpacing = 3.0;
              // AuroraHoverTile padding: vertical: 6 (top) + 6 (bottom) => 12 total
              const tileVerticalPaddingTotal = 12.0;
              // AuroraHoverTile border/margin overhead: 1.5 top + 1.5 bottom => 3
              const borderOverhead = 3.0;
              // Safety for font leading/rounding
              const safetyFudge = 6.0;

              final scaledWordFont = textScaler.scale(wordFontSize);
              final scaledScoreFont = textScaler.scale(scoreFontSize);

              final dynamicContentHeight =
                  scaledWordFont + interTextSpacing + scaledScoreFont;
              final targetHeight =
                  dynamicContentHeight +
                  tileVerticalPaddingTotal +
                  borderOverhead +
                  safetyFudge;

              double computedAspectRatio = tileWidth / targetHeight;
              // Clamp to keep aesthetics across devices
              computedAspectRatio = computedAspectRatio
                  .clamp(1.8, 2.6)
                  .toDouble();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: computedAspectRatio,
                ),
                itemCount: topCount,
                itemBuilder: (context, index) {
                  final r = recs[index];
                  final grad = gradientFor(r.score);
                  return AuroraHoverTile(
                    emphasize: index == 0,
                    onTap: () => onSelectWord(r.word),
                    borderGradientOverride: grad,
                    // Enable glow by default for medal tiles
                    animatedGlow: true,
                    // Tighter vertical padding for more rectangular look
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          r.word.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          r.score.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
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
                    return InkWell(
                      onTap: () => onSelectWord(w),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF15151A,
                            ).withValues(alpha: 0.5),
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
