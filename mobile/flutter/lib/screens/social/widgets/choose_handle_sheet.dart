import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/glass_sheet.dart';

/// Regex the backend also enforces (`PATCH /users/me/username`) — letters,
/// digits, underscore only, 3-20 chars. Duplicated here (not imported) since
/// this is the only client-side call site; kept in sync by inspection.
final RegExp _handleFormat = RegExp(r'^[A-Za-z0-9_]{3,20}$');

/// Best-effort handle suggested from the user's display name — falls back to
/// whatever auto-generated username the account already has if the name
/// can't produce a valid handle (missing, too short, non-Latin, etc.).
String suggestedHandleFrom({required String? name, required String? fallback}) {
  final firstWord = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .firstWhere((w) => w.isNotEmpty, orElse: () => '');
  var cleaned = firstWord.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
  if (cleaned.length > 16) cleaned = cleaned.substring(0, 16);
  if (cleaned.length >= 3) return cleaned;
  final fb = (fallback ?? '').trim();
  return fb.isNotEmpty ? fb : 'user';
}

/// First-entry-to-Community prompt: lets the user pick their own handle
/// instead of keeping whatever `core/username_generator.py` auto-generated
/// at signup (a name/email-derived string plus a random numeric suffix,
/// e.g. `Zealovaqa08189412` for an email-only signup — not something anyone
/// would choose to share, even though it's shown with a copy button as if
/// it were meant to be).
///
/// Shown once (gated by [communityHandlePromptShownKey] in
/// `social_screen.dart`); "Not now" keeps the existing handle and never
/// forces the user through this again.
class ChooseHandleSheet extends ConsumerStatefulWidget {
  final String? currentUsername;
  final String? displayName;

  const ChooseHandleSheet({
    super.key,
    required this.currentUsername,
    required this.displayName,
  });

  @override
  ConsumerState<ChooseHandleSheet> createState() => _ChooseHandleSheetState();
}

class _ChooseHandleSheetState extends ConsumerState<ChooseHandleSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: suggestedHandleFrom(
      name: widget.displayName,
      fallback: widget.currentUsername,
    ),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _formatError(String value) {
    if (value.isEmpty) return null; // don't nag before they've typed
    if (!_handleFormat.hasMatch(value)) {
      return '3-20 characters: letters, numbers, and underscores only.';
    }
    return null;
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    final formatError = _formatError(value);
    if (formatError != null) {
      setState(() => _error = formatError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).updateUsername(value);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // The repo throws with the server's own detail message ("That handle
      // is already taken.") — strip the generic `Exception: ` wrapper so it
      // reads as a plain sentence.
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _saving = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final cardBg = tc.elevated;
    final cardBorder = tc.cardBorder;

    return GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick your Community handle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "This is what other members see and search for — you can change "
              "it later from Settings.",
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.3),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _error != null ? Colors.red.shade400 : cardBorder, // accent-allowlist: error/destructive - must stay red
                ),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 20,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '@',
                  prefixStyle: TextStyle(fontSize: 16, color: textSecondary),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _error = _formatError(v)),
                onSubmitted: (_) => _save(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.red.shade400), // accent-allowlist: error/destructive - must stay red
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade400), // accent-allowlist: error/destructive - must stay red
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save handle',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                child: Text(
                  'Not now',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
