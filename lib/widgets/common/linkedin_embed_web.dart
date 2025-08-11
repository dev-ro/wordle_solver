// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class LinkedInEmbedSection extends StatefulWidget {
  final Widget fallback;
  final String profileUrl;
  const LinkedInEmbedSection({
    super.key,
    required this.fallback,
    required this.profileUrl,
  });

  @override
  State<LinkedInEmbedSection> createState() => _LinkedInEmbedSectionState();
}

class _LinkedInEmbedSectionState extends State<LinkedInEmbedSection> {
  late final String _viewType = 'linkedin-embed-${identityHashCode(this)}';
  html.DivElement? _container;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Register view factory once per instance
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _container = html.DivElement()
        ..style.width = '100%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center';
      // Create badge container
      final badge = html.DivElement()
        ..classes.add('badge-base')
        ..attributes['data-test-id'] = 'linkedin-badge'
        ..attributes['data-locale'] = 'en_US'
        ..attributes['data-size'] = 'medium'
        ..attributes['data-theme'] = 'dark'
        ..attributes['data-type'] = 'HORIZONTAL'
        ..attributes['data-vanity'] = 'debro'
        ..attributes['data-version'] = 'v1'
        ..style.margin = '6px';
      _container!.children.add(badge);

      // Defer script load to avoid blocking FMP
      Future.microtask(_ensureScriptLoaded)
          .then((_) {
            if (!mounted) return;
            setState(() => _loaded = true);
          })
          .catchError((_) {
            // Leave _loaded false; fallback will be shown
          });
      return _container!;
    });
  }

  Future<void> _ensureScriptLoaded() async {
    // Check if script already present
    final scripts = html.document.querySelectorAll('script');
    html.ScriptElement? existing;
    for (final s in scripts.whereType<html.ScriptElement>()) {
      if ((s.src).contains('platform.linkedin.com/in.js')) {
        existing = s;
        break;
      }
    }
    if (existing == null) {
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..async = true
        ..defer = true
        ..src = 'https://platform.linkedin.com/in.js';
      html.document.body?.append(script);
      // Give the script a bit of time to process
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Trigger plugin parse if available
    final badgeScript =
        html.document.createElement('script') as html.ScriptElement;
    badgeScript.text = 'if(window.IN && IN.parse){IN.parse();}';
    html.document.body?.append(badgeScript);
  }

  @override
  Widget build(BuildContext context) {
    // If not loaded, show fallback; once loaded, show the embed
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_loaded) widget.fallback,
        if (_loaded)
          SizedBox(height: 88, child: HtmlElementView(viewType: _viewType)),
      ],
    );
  }
}
