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
  final String? Function()? twiTextBuilder;
  final bool circle;
  final Color? iconColor;

  const ReadAloudButton({
    super.key,
    required this.textBuilder,
    this.twiTextBuilder,
    this.circle = false,
    this.iconColor,
  });

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  bool _speaking = false;
  bool _loading = false;
  String _language = 'English';
  int _requestId = 0;
  int _activityId = 0;

  @override
  void initState() {
    super.initState();
    WebSpeechService.activity.addListener(_onActivityChanged);
  }

  void _onActivityChanged() {
    if (_speaking && WebSpeechService.activity.value != _activityId && mounted) {
      setState(() { _speaking = false; _loading = false; });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Read aloud'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggle() {
    if (_speaking) {
      _requestId++;
      WebSpeechService.stop();
      setState(() { _speaking = false; _loading = false; });
      return;
    }
    final text = _language == 'Twi' ? widget.twiTextBuilder?.call() : widget.textBuilder();
    if (text == null || text.trim().isEmpty) {
      _showMessage('A Twi description is not currently available.');
      return;
    }
    final language = _language;
    _activityId = WebSpeechService.startSession();
    setState(() { _speaking = true; _loading = language == 'Twi'; });
    final requestId = ++_requestId;
    final play = language == 'Twi'
        ? WebSpeechService.speakTwi(text, () {
            if (mounted && requestId == _requestId) {
              setState(() => _loading = false);
            }
          })
        : WebSpeechService.speak(text);
    unawaited(play.then((_) {
      if (mounted && requestId == _requestId) {
        setState(() { _speaking = false; _loading = false; });
      }
    }).catchError((_) {
      if (!mounted || requestId != _requestId) return;
      setState(() { _speaking = false; _loading = false; });
        _showMessage(language == 'Twi'
          ? 'Twi audio could not be generated. Please try again.'
          : 'English audio could not be played. Please try again.');
    }));
  }

  @override
  void dispose() {
    WebSpeechService.activity.removeListener(_onActivityChanged);
    if (_speaking) WebSpeechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportsLanguage = _language == 'Twi'
      ? WebSpeechService.isTwiSupported
      : WebSpeechService.isSupported;
    if (!supportsLanguage) return const SizedBox.shrink();

    final icon = _speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined;
    final label = _loading ? 'Generating audio' : (_speaking ? 'Stop reading' : 'Read aloud');
    final selector = widget.twiTextBuilder == null ? const SizedBox.shrink() : DropdownButton<String>(
      value: _language,
      underline: const SizedBox.shrink(),
      isDense: true,
      dropdownColor: kWhite,
      iconEnabledColor: kGreen,
      selectedItemBuilder: (_) => [
        const Text('English', style: TextStyle(fontSize: 12, color: Colors.black87)),
        const Text('Twi', style: TextStyle(fontSize: 12, color: Colors.black87)),
      ],
      items: const [
        DropdownMenuItem(
          value: 'English',
          child: Text('English', style: TextStyle(color: Colors.black87)),
        ),
        DropdownMenuItem(
          value: 'Twi',
          child: Text('Twi', style: TextStyle(color: Colors.black87)),
        ),
      ],
      onChanged: _speaking ? null : (value) => setState(() => _language = value ?? 'English'),
    );

    if (widget.circle) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.twiTextBuilder != null)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: kDeep.withValues(alpha: 0.9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                borderRadius: kBRPill,
              ),
              child: DropdownButton<String>(
                value: _language,
                underline: const SizedBox.shrink(),
                isDense: true,
                dropdownColor: kWhite,
                iconEnabledColor: Colors.white,
                iconDisabledColor: Colors.white70,
                style: const TextStyle(fontSize: 11, color: Colors.white),
                selectedItemBuilder: (_) => [
                  const Text('English', style: TextStyle(fontSize: 11, color: Colors.white)),
                  const Text('Twi', style: TextStyle(fontSize: 11, color: Colors.white)),
                ],
                items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English', style: TextStyle(color: Colors.black87)),
                      ),
                      DropdownMenuItem(
                        value: 'Twi',
                        child: Text('Twi', style: TextStyle(color: Colors.black87)),
                      ),
                ],
                onChanged: _speaking ? null : (value) => setState(() => _language = value ?? 'English'),
              ),
            ),
          if (widget.twiTextBuilder != null) const SizedBox(width: 8),
          Semantics(
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
          ),
          if (_loading) ...[
            const SizedBox(width: 6),
            const Text(
              'Generating...',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ],
      );
    }

    return TextButton.icon(
      onPressed: _toggle,
      style: TextButton.styleFrom(
        foregroundColor: _speaking ? kUnhealthyTx : kGreen,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      icon: Icon(icon, size: 16),
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        selector,
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
