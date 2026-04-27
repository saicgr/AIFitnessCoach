/// Chat-bubble action card that renders when the coach agent returns a
/// `share_artifact_generated` action_data payload.
///
/// Shows the public URL with two CTAs:
///   1. **Copy & share link** — clipboard copy + system share sheet
///   2. **Open in app** — uses `deep_link` params to navigate to the
///      matching screen (Workout tab for plans, Reports for PRs, etc.).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import 'package:fitwiz/core/constants/branding.dart';

class ShareArtifactCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ShareArtifactCard({super.key, required this.data});

  String? get _url => data['url'] as String?;
  String? get _scope => data['scope'] as String?;
  String? get _period => data['period'] as String?;
  String? get _deepLink => data['deep_link'] as String?;
  bool get _success => data['success'] != false;
  String? get _error => data['error'] as String?;

  String get _label {
    final p = (_period ?? '').toLowerCase();
    final s = (_scope ?? '').toLowerCase();
    if (s == 'workout' && p == 'today') return "Today's workout";
    if (s == 'plan' && p == 'week') return 'This week\'s plan';
    if (s == 'plan' && p == 'month') return 'This month\'s program';
    if (s == 'plan' && p == 'ytd') return 'Year-to-date plan';
    if (s == 'prs') return 'PRs this $p';
    if (s == 'one_rm') return '1RM progress';
    if (s == 'summary') return 'Summary';
    return 'Share';
  }

  Future<void> _onCopyShare(BuildContext context) async {
    final url = _url;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    await Share.share('$_label — ${Branding.appName}\n$url', subject: '${Branding.appName}');
  }

  void _onOpenInApp(BuildContext context) {
    // Plan-period shares route to the Workout tab; PRs/1RM/summary route
    // to Reports. Single-workout shares route to the workout-detail.
    final s = (_scope ?? 'plan').toLowerCase();
    if (s == 'workout') {
      context.push('/workout-tab');
      return;
    }
    if (s == 'prs' || s == 'one_rm' || s == 'summary') {
      context.push('/reports');
      return;
    }
    context.push('/workout-tab');
  }

  @override
  Widget build(BuildContext context) {
    if (!_success) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.4)),
        ),
        child: Text(
          _error ?? 'Could not create share link.',
          style: const TextStyle(fontSize: 13, color: AppColors.error),
        ),
      );
    }
    final url = _url;
    if (url == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.ios_share_rounded,
                    size: 18, color: AppColors.cyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.pureBlack.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url.replaceFirst(RegExp(r'^https?://'), ''),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _onCopyShare(context),
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('Copy & share'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 0.5,
                height: 36,
                color: AppColors.cardBorder,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _onOpenInApp(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Open in app'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
