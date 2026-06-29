import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_widgets.dart';

/// Phase 6 (Cinematic Canvas) sign-in page.
///
/// Immersive full-bleed layout on [AppColors.stage]. Wordmark uses the brand
/// gradient. Primary CTA uses [AuthGradientButton] — signals the transition
/// from "browsing" to "experience" per the Cinematic Canvas spec.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
    await ref.read(authProvider.notifier).signIn(
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
                const SizedBox(height: 64),

                // ── Wordmark ──────────────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.brandGradient,
                  ).createShader(bounds),
                  child: const Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  context.l10n.authSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Email ─────────────────────────────────────────────────────
                AuthField(
                  key: const Key('emailField'),
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
                  key: const Key('passwordField'),
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
                  key: const Key('signInButton'),
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                  label: context.l10n.authSignInButton,
                ),

                const SizedBox(height: 20),

                // ── Secondary actions ─────────────────────────────────────────
                TextButton(
                  key: const Key('registerLink'),
                  onPressed: () => context.go(AppRoutes.register),
                  child: Text(
                    context.l10n.authNoAccount,
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
