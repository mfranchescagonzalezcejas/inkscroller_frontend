import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../auth_error_text.dart';
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
    final isProfileCompletion = currentAuthState.profileCompletionPending;

    if (!isProfileCompletion && !_acceptedTerms) {
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

    if (isProfileCompletion) {
      await ref
          .read(authProvider.notifier)
          .completeProfile(username: username, birthDate: birthDate);
      if (!mounted) return;

      final completedAuthState = ref.read(authProvider);
      if (!completedAuthState.profileCompletionPending &&
          completedAuthState.error == null) {
        context.go(AppRoutes.home);
      }
      return;
    }

    await ref
        .read(authProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          username: username,
          password: _passwordController.text,
          birthDate: birthDate,
        );
    if (!mounted) return;

    // Only navigate away when the account was actually created and the user
    // is signed in. If signUp itself failed (email in use, weak password,
    // network error), the user stays on this page to retry.
    // When signed in but unverified, the router redirects to /verify-email.
    if (ref.read(authProvider).user != null) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _signOutRecovery() async {
    final currentAuthState = ref.read(authProvider);
    if (currentAuthState.isLoading || currentAuthState.registrationInProgress) {
      return;
    }

    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;

    final completedAuthState = ref.read(authProvider);
    if (completedAuthState.user == null && completedAuthState.error == null) {
      context.go(AppRoutes.login);
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

  Future<void> _openTermsUrl() async {
    final uri = Uri.parse('https://inkscroller-privacy.vercel.app/');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        AppFeedback.showWarning(
          context,
          title: context.l10n.authTermsAcknowledgement,
        );
      }
    } on Exception catch (e, st) {
      debugPrint('[TermsLink] Failed to launch URL: $e\n$st');
      if (!mounted) return;
      AppFeedback.showWarning(
        context,
        title: context.l10n.authTermsAcknowledgement,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isProfileCompletion = authState.profileCompletionPending;
    final isActionLocked =
        authState.isLoading || authState.registrationInProgress;
    final isRouteLocked = isActionLocked || isProfileCompletion;

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        final title = authErrorText(context, next.error);
        AppFeedback.showError(context, title: title);
      }
    });

    return PopScope<void>(
      canPop: !isRouteLocked,
      child: Scaffold(
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
                    child: isProfileCompletion
                        ? const SizedBox(height: 48)
                        : IconButton(
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
                    isProfileCompletion
                        ? context.l10n.authCompleteProfileTitle
                        : context.l10n.authCreateAccountTitle,
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
                    isProfileCompletion
                        ? context.l10n.authCompleteProfileSubtitle
                        : context.l10n.authCreateAccountSubtitle,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 36),

                  if (!isProfileCompletion) ...<Widget>[
                    // ── Email ───────────────────────────────────────────────────
                    AuthField(
                      key: const Key('registerEmailField'),
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
                  ],

                  // ── Username ──────────────────────────────────────────────────
                  AuthField(
                    key: const Key('registerUsernameField'),
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

                  if (!isProfileCompletion) ...<Widget>[
                    // ── Password ────────────────────────────────────────────────
                    AuthField(
                      key: const Key('registerPasswordField'),
                      controller: _passwordController,
                      label: context.l10n.authPasswordLabel,
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      keyboardType: TextInputType.visiblePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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
                      key: const Key('registerConfirmPasswordField'),
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
                  ],

                  // ── Birth date ────────────────────────────────────────────────
                  AuthField(
                    key: const Key('registerBirthDateField'),
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

                  if (!isProfileCompletion) ...<Widget>[
                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: _acceptedTerms,
                        onChanged: isActionLocked
                            ? null
                            : (value) => setState(
                                () => _acceptedTerms = value ?? false),
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                      ),
                      title: Text(
                        context.l10n.authTermsAcknowledgement,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        onPressed: isActionLocked ? null : _openTermsUrl,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: context.l10n.authTermsAcknowledgement,
                      ),
                      onTap: isActionLocked
                          ? null
                          : () => setState(
                              () => _acceptedTerms = !_acceptedTerms),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Primary CTA ───────────────────────────────────────────────
                  AuthGradientButton(
                    key: const Key('createAccountButton'),
                    onPressed: isActionLocked ? null : _submit,
                    isLoading:
                        authState.isLoading || authState.registrationInProgress,
                    label: isProfileCompletion
                        ? context.l10n.authCompleteProfileButton
                        : context.l10n.authCreateAccountButton,
                  ),

                  const SizedBox(height: 20),

                  // ── Secondary actions ─────────────────────────────────────────
                  if (!isProfileCompletion)
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

                  if (!isProfileCompletion)
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

                  if (isProfileCompletion)
                    TextButton(
                      onPressed: isActionLocked ? null : _signOutRecovery,
                      child: Text(
                        context.l10n.profileSignOutAction,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
