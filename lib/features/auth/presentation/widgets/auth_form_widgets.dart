import 'package:flutter/material.dart';

import '../../../../core/constants/layout.dart';
import '../../../../core/design/design_tokens.dart';

/// Phase 6 text field for auth forms.
///
/// Surface-shift containment (no border line rule) with ghost border fallback
/// per the Cinematic Canvas "Ghost Border" spec.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.authFieldRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}

/// Brand-gradient primary button.
///
/// Per DESIGN.md, the brand gradient is reserved for transitions from
/// "browsing" to "experience" — sign in and account creation qualify.
class AuthGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const AuthGradientButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPressed != null ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppLayout.authButtonRadius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppLayout.authButtonRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppLayout.authButtonRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.authButtonMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppTypography.labelLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.voidLowest,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
