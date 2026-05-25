import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/providers/subscription_provider.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/account_deletion_service.dart';
import '../screens/settings/widgets/dialog_bullet_point.dart';
import 'app_snackbar.dart';
import 'delete_account_progress_dialog.dart';

import '../l10n/generated/app_localizations.dart';
/// Single source of truth for the Delete Account flow used by both the
/// Profile screen and Settings → Danger Zone. Shows the confirmation dialog
/// (with inline password field for email-auth users), runs the backend
/// delete via [AccountDeletionService], and navigates to /intro on success.
Future<void> showDeleteAccountFlow(BuildContext context, WidgetRef ref) async {
  // Pre-flight: warn if there's an active paid subscription. Neither store
  // auto-cancels when the auth user is deleted — the user keeps getting
  // charged. Surface this BEFORE we destroy data.
  final subscription = ref.read(subscriptionProvider);
  if (subscription.tier != SubscriptionTier.free &&
      subscription.tier != SubscriptionTier.lifetime) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final storeName = isIOS ? 'App Store' : 'Play Store';
    final manageUrl = isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteAccountFlowActiveSubscription),
        content: Text(
          'Deleting your account does NOT cancel your $storeName subscription. '
          'You will continue to be billed unless you cancel from the $storeName first.\n\n'
          'Cancel your subscription, then come back here to delete your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Open $storeName'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context).deleteAccountFlowDeleteAnyway),
          ),
        ],
      ),
    );
    if (proceed != true) {
      await launchUrl(
        Uri.parse(manageUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    if (!context.mounted) return;
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final supabaseUser = Supabase.instance.client.auth.currentUser;
  final authProvider =
      (supabaseUser?.appMetadata['provider'] as String?) ?? 'email';
  final isOAuthUser = authProvider != 'email';
  final passwordController = TextEditingController();

  bool obscured = true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocal) => AlertDialog(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      title: Row(
        children: [
          Icon(Icons.delete_forever, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).deleteAccountFlowDeleteAccount,
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimary
                  : AppColorsLight.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).deleteAccountFlowThisActionCannotBe,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deleteAccountFlowThisWillPermanentlyDelete,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            DialogBulletPoint(
              text: 'Your account and profile',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All workout history',
              color: AppColors.error,
              isDark: isDark,
            ),
            DialogBulletPoint(
              text: 'All saved preferences',
              color: AppColors.error,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).deleteAccountFlowYouWillNeedTo,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
            if (!isOAuthUser) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).deleteAccountFlowConfirmWithYourPassword,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscured,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).authPasswordHint,
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: (isDark
                            ? AppColors.textMuted
                            : AppColorsLight.textMuted)
                        .withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: (isDark
                          ? AppColors.pureBlack
                          : AppColorsLight.pureWhite)
                      .withValues(alpha: 0.6),
                  prefixIcon: Icon(Icons.key_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                    onPressed: () => setLocal(() => obscured = !obscured),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            AppLocalizations.of(context).buttonCancel,
            style: TextStyle(
              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (!isOAuthUser && passwordController.text.isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).deleteAccountFlowPleaseEnterYourPassword)),
              );
              return;
            }
            Navigator.of(dialogContext).pop(true);
          },
          child: Text(
            AppLocalizations.of(context).settingsDeleteAccount,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
    ),
  );

  final password = isOAuthUser ? null : passwordController.text;
  // Defer disposal until after the dialog's exit animation finishes — the
  // child TextField can still rebuild against the controller during the
  // pop transition, and disposing synchronously throws
  // "TextEditingController used after being disposed".
  WidgetsBinding.instance.addPostFrameCallback((_) {
    passwordController.dispose();
  });

  if (confirmed != true) return;
  if (!context.mounted) return;

  await _runDelete(context, ref, password: password);
}

Future<void> _runDelete(
  BuildContext context,
  WidgetRef ref, {
  String? password,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  final authState = ref.read(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) {
    AppSnackBar.error(context, 'Error: User not found');
    return;
  }

  // Proactive session refresh. The API client only attaches Authorization
  // when there's a live token; if a prior failed attempt nuked the session,
  // the next DELETE goes out header-less and the backend returns
  // "Authorization header required". Refresh first; if that fails, route the
  // user to sign in again instead of firing a doomed request.
  final supabaseAuth = Supabase.instance.client.auth;
  if (supabaseAuth.currentSession == null) {
    try {
      await supabaseAuth.refreshSession();
    } catch (_) {}
  }
  if (supabaseAuth.currentSession == null) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteAccountFlowSignInAgain),
        content: const Text(
          'Your session has expired. Please sign out and sign back in, '
          'then try deleting your account again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).healthSyncOk),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authStateProvider.notifier).signOut();
              router.go('/intro');
            },
            child: Text(AppLocalizations.of(context).settingsLogout),
          ),
        ],
      ),
    );
    return;
  }

  if (!context.mounted) return;
  final status = ValueNotifier<String>('Deleting account from server…');
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => DeleteAccountProgressDialog(status: status),
  );

  try {
    await ref.read(accountDeletionServiceProvider).deleteAccount(
          userId: userId,
          password: password,
          status: status,
        );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    router.go('/intro');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (navigator.canPop()) navigator.pop();
  } catch (e) {
    debugPrint('[DeleteAccount] error: $e');
    if (navigator.canPop()) navigator.pop();
    String errorMsg = e.toString();
    if (e is DioException && e.response?.data is Map) {
      errorMsg = (e.response?.data as Map)['detail']?.toString() ?? errorMsg;
    }
    final lower = errorMsg.toLowerCase();
    final isReauth = lower.contains('401') ||
        lower.contains('invalid password') ||
        lower.contains('re-authentication');
    if (isReauth && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).deleteAccountFlowReAuthenticationRequired),
          content: Text(
            AppLocalizations.of(context).deleteAccountFlowWeCouldNotVerify,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).healthSyncOk),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(authStateProvider.notifier).signOut();
                router.go('/intro');
              },
              child: Text(AppLocalizations.of(context).deleteAccountFlowResetPassword),
            ),
          ],
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    status.dispose();
  }
}
