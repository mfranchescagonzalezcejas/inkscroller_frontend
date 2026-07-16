import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';

/// Post-registration email verification page.
///
/// Shown after a successful sign-up. Guides the user through email
/// verification and provides options to resend the verification email
/// or sign out and use a different account.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final email = authState.user?.email ?? '';
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.stage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 80),

              // ── Icon ────────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              // ── Title ───────────────────────────────────────────────────
              Text(
                l10n.authVerifyEmailTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              // ── Body ────────────────────────────────────────────────────
              Text(
                l10n.authVerifyEmailBody(email),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              if (authState.emailVerificationSent)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.authVerifyEmailSent,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),

              const SizedBox(height: 36),

              // ── "I've verified — continue" CTA ─────────────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: AppColors.brandGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isChecking ? null : _onCheckVerification,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.voidLowest,
                              ),
                            )
                          : Text(
                              l10n.authVerifyEmailContinue,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.voidLowest,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Resend button ───────────────────────────────────────────
              TextButton(
                onPressed:
                    authState.isLoading || !authState.canResendVerification
                        ? null
                        : _onResend,
                child: Text(
                  authState.canResendVerification
                      ? l10n.authVerifyEmailResend
                      : l10n.authVerifyEmailWait,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: authState.canResendVerification
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Use a different email ───────────────────────────────────
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (!context.mounted) return;
                        context.go(AppRoutes.register);
                      },
                child: Text(
                  l10n.authVerifyEmailDifferentEmail,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onCheckVerification() async {
    setState(() => _isChecking = true);

    final isVerified = await ref.read(authProvider.notifier).checkEmailVerification();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isVerified) {
      AppFeedback.showSuccess(context, title: context.l10n.authVerifyEmailSuccess);
      context.go(AppRoutes.home);
    } else {
      AppFeedback.showInfo(
        context,
        title: context.l10n.authVerifyEmailNotYet,
      );
    }
  }

  Future<void> _onResend() async {
    await ref.read(authProvider.notifier).sendVerificationEmail();
    if (!mounted) return;
    AppFeedback.showInfo(
      context,
      title: context.l10n.authVerifyEmailResent,
    );
  }
}
