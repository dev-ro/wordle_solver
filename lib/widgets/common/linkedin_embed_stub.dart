import 'package:flutter/widgets.dart';

class LinkedInEmbedSection extends StatelessWidget {
  final Widget fallback;
  final String profileUrl;
  const LinkedInEmbedSection({
    super.key,
    required this.fallback,
    required this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return fallback;
  }
}
