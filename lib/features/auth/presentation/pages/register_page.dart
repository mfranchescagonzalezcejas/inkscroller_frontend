import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_widgets.dart';

/// Phase 6 (Cinematic Canvas) account creation page.
///
/// Consistent with [LoginPage] — same [AppColors.stage] surface, same
/// [AuthField] style, same [AuthGradientButton] CTA. Uses an inline back
/// button instead of a full [AppBar] to keep the layout lightweight.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        AppFeedback.showError(context, title: next.error!);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.stage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ── Back nav ──────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Header ────────────────────────────────────────────────────
                Text(
                  context.l10n.authCreateAccountTitle,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  context.l10n.authCreateAccountSubtitle,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Email ─────────────────────────────────────────────────────
                AuthField(
                  controller: _emailController,
                  label: context.l10n.authEmailLabel,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.authEmailRequired;
                    }
                    if (!value.contains('@')) {
                      return context.l10n.authEmailInvalid;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Password ──────────────────────────────────────────────────
                AuthField(
                  controller: _passwordController,
                  label: context.l10n.authPasswordLabel,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.authPasswordRequired;
                    }
                    if (value.length < 6) {
                      return context.l10n.authPasswordTooShort;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // ── Primary CTA ───────────────────────────────────────────────
                AuthGradientButton(
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                  label: context.l10n.authCreateAccountButton,
                ),

                const SizedBox(height: 20),

                // ── Secondary actions ─────────────────────────────────────────
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(
                    context.l10n.authHaveAccount,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(
                    context.l10n.authContinueAsGuest,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
