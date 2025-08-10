import 'package:flutter/material.dart';

class FillerResults extends StatelessWidget {
  final List<MapEntry<String, int>> results;
  final void Function(String word) onSelectWord;
  final String title;
  final bool dense;

  const FillerResults({
    super.key,
    required this.results,
    required this.onSelectWord,
    required this.title,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (results.isEmpty) return const SizedBox.shrink();

    final display = results.take(9).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
          ),
          itemCount: display.length,
          itemBuilder: (context, index) {
            final e = display[index];
            return InkWell(
              onTap: () => onSelectWord(e.key),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF15151A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        e.key.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      e.value.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
