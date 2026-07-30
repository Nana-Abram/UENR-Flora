// lib/widgets/app_footer.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Plain, centered tagline bar shown at the bottom of a page's content.
/// Explorer, Learn, Article, and Scan each used to define their own
/// near-identical copy of this (same layout, minor padding/wording
/// differences); this is the one shared version.
///
/// Home's footer is intentionally NOT built on this — it also shows a
/// logo, rich text, and a responsive two-column layout, not just a
/// centered tagline, so forcing it into this widget would need more
/// optional parameters than it's worth.
class AppFooter extends StatelessWidget {
  final String message;

  /// Scan/Learn/Article's footer sits on a Material with elevation/shadow
  /// above it; Explorer's is a plain white bar. Both are supported here
  /// rather than picking one and silently changing the other's look.
  final bool elevated;

  const AppFooter({super.key, required this.message, this.elevated = true});

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: double.infinity,
      color: elevated ? null : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 11, color: kMu),
          textAlign: TextAlign.center,
        ),
      ),
    );
    if (!elevated) return bar;
    return Material(color: Colors.white, elevation: 4, shadowColor: Colors.black26, child: bar);
  }
}
