import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Lifecycle of the card within a single message bubble.
enum _ProposalUiState { idle, applying, applied, dismissed, failed, expired }

/// Card shown below an assistant message when the AI has proposed a workout
/// change via `propose_workout_change`. The user taps Apply to run the real
/// mutation, or Not now to dismiss — both call the backend so the
/// chat_pending_proposals row gets marked in the DB.
class ProposedChangeCard extends ConsumerStatefulWidget {
  final String proposalId;
  final String proposalToken;
  final String summary;
  final String? reason;
  final String? proposedAction;
  final DateTime? expiresAt;

  const ProposedChangeCard({
    super.key,
    required this.proposalId,
    required this.proposalToken,
    required this.summary,
    this.reason,
    this.proposedAction,
    this.expiresAt,
  });

  @override
  ConsumerState<ProposedChangeCard> createState() => _ProposedChangeCardState();
}

class _ProposedChangeCardState extends ConsumerState<ProposedChangeCard> {
  late _ProposalUiState _state = _initialState();
  String? _errorMessage;

  _ProposalUiState _initialState() {
    final expires = widget.expiresAt;
    if (expires != null && expires.isBefore(DateTime.now())) {
      return _ProposalUiState.expired;
    }
    return _ProposalUiState.idle;
  }

  Future<void> _onApply() async {
    if (_state != _ProposalUiState.idle && _state != _ProposalUiState.failed) {
      return;
    }
    HapticService.medium();
    setState(() {
      _state = _ProposalUiState.applying;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.applyProposal(
        proposalId: widget.proposalId,
        proposalToken: widget.proposalToken,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        setState(() => _state = _ProposalUiState.applied);
        // Refresh the workouts so today's view reflects the change immediately.
        ref.invalidate(todayWorkoutProvider);
        // workoutsProvider is the broader list used by the schedule screen.
        try {
          await ref.read(workoutsProvider.notifier).refresh();
        } catch (_) {
          // Non-fatal — the next pull will pick it up.
        }
      } else {
        if (!mounted) return;
        setState(() {
          _state = _ProposalUiState.failed;
          _errorMessage = (result['detail'] as String?) ?? 'Could not apply.';
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      // Map server-side status codes to terminal states so the user doesn't
      // get stuck tapping a button that will never succeed.
      final code = e.response?.statusCode;
      setState(() {
        if (code == 409) {
          _state = _ProposalUiState.applied;
        } else if (code == 410) {
          _state = _ProposalUiState.expired;
        } else {
          _state = _ProposalUiState.failed;
          _errorMessage = 'Apply failed (${code ?? 'network'}). Try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ProposalUiState.failed;
        _errorMessage = 'Unexpected error. Try again.';
      });
    }
  }

  Future<void> _onDismiss() async {
    if (_state != _ProposalUiState.idle && _state != _ProposalUiState.failed) {
      return;
    }
    HapticService.selection();
    setState(() => _state = _ProposalUiState.dismissed);
    // Fire-and-forget — the card is already hidden; any error is logged.
    unawaited(
      ref.read(chatRepositoryProvider).dismissProposal(
            proposalId: widget.proposalId,
            proposalToken: widget.proposalToken,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.orange.withValues(alpha: 0.08)
              : AppColors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_fix_high_rounded,
                  size: 18,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.summary,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            if ((widget.reason ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  widget.reason!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    switch (_state) {
      case _ProposalUiState.applied:
        return _StatusRow(
          icon: Icons.check_circle_rounded,
          color: AppColors.green,
          label: 'Applied',
        );
      case _ProposalUiState.dismissed:
        return _StatusRow(
          icon: Icons.check_circle_outline,
          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          label: 'Dismissed',
        );
      case _ProposalUiState.expired:
        return _StatusRow(
          icon: Icons.schedule,
          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          label: 'Expired — ask again for a fresh suggestion',
        );
      case _ProposalUiState.applying:
      case _ProposalUiState.idle:
      case _ProposalUiState.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_state == _ProposalUiState.failed &&
                (_errorMessage ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _state == _ProposalUiState.applying
                        ? null
                        : _onDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      foregroundColor: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                    ),
                    child: const Text(
                      'Not now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _state == _ProposalUiState.applying
                        ? null
                        : _onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.orange.withValues(alpha: 0.4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _state == _ProposalUiState.applying
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Text(
                            'Apply change',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

