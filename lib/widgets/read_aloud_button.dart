// lib/widgets/read_aloud_button.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/web_speech_service.dart';

/// Toggle button that reads [textBuilder]'s output aloud via the browser's
/// speech synthesis, switching to a stop icon while speaking. Renders
/// nothing when the browser doesn't support the Web Speech API.
///
/// Two looks share the same play/stop logic: [circle] for a small icon-only
/// button dropped into image headers (alongside favourite/share buttons),
/// or the default labelled pill for content pages.
class ReadAloudButton extends StatefulWidget {
  final String Function() textBuilder;
  final bool circle;
  final Color? iconColor;

  const ReadAloudButton({
    super.key,
    required this.textBuilder,
    this.circle = false,
    this.iconColor,
  });

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  bool _speaking = false;

  void _toggle() {
    if (_speaking) {
      WebSpeechService.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    unawaited(WebSpeechService.speak(widget.textBuilder()).then((_) {
      if (mounted) setState(() => _speaking = false);
    }));
  }

  @override
  void dispose() {
    if (_speaking) WebSpeechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!WebSpeechService.isSupported) return const SizedBox.shrink();

    final icon = _speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined;
    final label = _speaking ? 'Stop reading' : 'Read aloud';

    if (widget.circle) {
      return Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Icon(icon, size: 16, color: widget.iconColor ?? Colors.white),
            ),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: _toggle,
      style: TextButton.styleFrom(
        foregroundColor: _speaking ? kUnhealthyTx : kGreen,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        _speaking ? 'Stop reading' : 'Read aloud',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
