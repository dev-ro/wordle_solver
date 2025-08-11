import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'aurora.dart';
import 'linkedin_embed_stub.dart'
    if (dart.library.html) 'linkedin_embed_web.dart'
    as embed;

class DeveloperFooter extends StatelessWidget {
  const DeveloperFooter({super.key});

  static final Uri _profileUri = Uri.parse('https://www.linkedin.com/in/debro');

  Future<void> _openProfile() async {
    await launchUrl(_profileUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: AuroraCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;
            final content = _FooterContent(onTap: _openProfile);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kIsWeb) ...[
                  // Web: optional embed loader with graceful fallback
                  embed.LinkedInEmbedSection(
                    fallback: content,
                    profileUrl: _profileUri.toString(),
                  ),
                ] else ...[
                  // Non-web platforms: simple, responsive fallback
                  content,
                ],
                const SizedBox(height: 8),
                if (!isNarrow)
                  Text(
                    'Connect with the developer',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FooterContent extends StatelessWidget {
  final VoidCallback onTap;
  const _FooterContent({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final avatar = CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF2C2D34),
          child: ClipOval(
            child: Image.asset(
              // Optional local fallback asset. If missing, the errorBuilder
              // ensures an icon is shown instead.
              'assets/avatar/debro.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) {
                return const Icon(Icons.person, color: Colors.white70);
              },
            ),
          ),
        );

        final linkText = Text(
          'linkedin.com/in/debro',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        );

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(width: 12),
            Flexible(child: linkText),
          ],
        );

        return Semantics(
          label: 'Developer profile footer. Link to LinkedIn profile.',
          button: true,
          child: InkWell(
            onTap: onTap,
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [row],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [row],
                  ),
          ),
        );
      },
    );
  }
}
