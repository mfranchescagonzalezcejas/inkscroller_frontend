import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../validation/registration_validators.dart';
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentAuthState = ref.read(authProvider);
    if (currentAuthState.isLoading || currentAuthState.registrationInProgress) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      AppFeedback.showError(context, title: context.l10n.authTermsRequired);
      return;
    }

    final birthDate = RegistrationValidators.parseBirthDate(
      _birthDateController.text,
    );
    if (birthDate == null) return;

    final username = RegistrationValidators.normalizeUsername(
      _usernameController.text,
    );

    await ref
        .read(authProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          username: username,
          password: _passwordController.text,
          birthDate: birthDate,
        );
    if (!mounted) return;

    final completedAuthState = ref.read(authProvider);
    final registrationSucceeded =
        !completedAuthState.registrationInProgress &&
        completedAuthState.error == null &&
        completedAuthState.user != null;

    if (registrationSucceeded) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedBirthDate = selectedDate;
      _birthDateController.text = _formatDate(selectedDate);
    });
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isActionLocked =
        authState.isLoading || authState.registrationInProgress;

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        AppFeedback.showError(context, title: next.error!);
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
                    onPressed: isActionLocked
                        ? null
                        : () => context.go(AppRoutes.login),
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

                // ── Email ───────────────────────────────────────────────────
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

                // ── Username ──────────────────────────────────────────────────
                AuthField(
                  controller: _usernameController,
                  label: context.l10n.authUsernameLabel,
                  icon: Icons.alternate_email,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.authUsernameRequired;
                    }
                    if (!RegistrationValidators.isValidUsername(value)) {
                      return context.l10n.authUsernameInvalid;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Password ────────────────────────────────────────────────
                AuthField(
                  controller: _passwordController,
                  label: context.l10n.authPasswordLabel,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
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

                const SizedBox(height: 12),

                // ── Confirm password ────────────────────────────────────────
                AuthField(
                  controller: _confirmPasswordController,
                  label: context.l10n.authConfirmPasswordLabel,
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    onPressed: isActionLocked
                        ? null
                        : () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.authConfirmPasswordRequired;
                    }
                    if (value != _passwordController.text) {
                      return context.l10n.authConfirmPasswordMismatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Birth date ────────────────────────────────────────────────
                AuthField(
                  controller: _birthDateController,
                  label: context.l10n.authBirthDateLabel,
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.done,
                  readOnly: true,
                  onTap: isActionLocked ? null : _pickBirthDate,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    final parsed = RegistrationValidators.parseBirthDate(
                      value ?? '',
                    );
                    if (parsed == null) {
                      return context.l10n.authBirthDateRequired;
                    }
                    if (!RegistrationValidators.isAllowedBirthDate(parsed)) {
                      return context.l10n.authBirthDateInvalid;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: isActionLocked
                      ? null
                      : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                  title: Text(
                    context.l10n.authTermsAcknowledgement,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Primary CTA ───────────────────────────────────────────────
                AuthGradientButton(
                  onPressed: isActionLocked ? null : _submit,
                  isLoading: authState.isLoading,
                  label: context.l10n.authCreateAccountButton,
                ),

                const SizedBox(height: 20),

                // ── Secondary actions ─────────────────────────────────────────
                TextButton(
                  onPressed: isActionLocked
                      ? null
                      : () => context.go(AppRoutes.login),
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
                  onPressed: isActionLocked
                      ? null
                      : () => context.go(AppRoutes.home),
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
