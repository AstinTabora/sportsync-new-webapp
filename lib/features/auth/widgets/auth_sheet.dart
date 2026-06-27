import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/core/utils/validators.dart';
import 'package:sportsync/features/auth/data/auth_repository.dart';

/// Bottom-sheet for email/password sign-in and account creation. Opened from
/// the Profile section; login is always optional.
class AuthSheet extends ConsumerStatefulWidget {
  const AuthSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const AuthSheet(),
    );
  }

  @override
  ConsumerState<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<AuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _signUp = true;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      final auth = ref.read(authRepositoryProvider);
      if (_signUp) {
        await auth.signUp(email: email, password: password, name: name);
      } else {
        await auth.signIn(email: email, password: password);
      }
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!isValidEmail(email)) {
      setState(() {
        _notice = null;
        _error = 'Enter your email above first.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        setState(() => _notice = 'Password reset email sent — check your inbox.');
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _social(Future<bool> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final ok = await action();
      if (ok && mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl3)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _signUp ? 'CREATE ACCOUNT' : 'WELCOME BACK',
                    style: AppTextStyles.headingBlack(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _signUp
                        ? 'Save your details for faster booking.'
                        : 'Sign in to your SportSync account.',
                    style: AppTextStyles.bodyBold(color: AppColors.slate400),
                  ),
                  const SizedBox(height: 20),
                  if (_signUp) ...[
                    _Field(
                      label: 'FULL NAME',
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _Field(
                    label: 'EMAIL ADDRESS',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: emailFieldValidator,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'PASSWORD',
                    controller: _password,
                    obscure: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: _signUp
                        ? passwordFieldValidator
                        : (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.slate400,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (!_signUp) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _forgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style:
                              AppTextStyles.bodyBold(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _Banner(
                      message: _error!,
                      icon: Icons.error_outline,
                      bg: AppColors.statusAmberBg,
                      iconColor: AppColors.statusAmber,
                    ),
                  ],
                  if (_notice != null) ...[
                    const SizedBox(height: 14),
                    _Banner(
                      message: _notice!,
                      icon: Icons.mark_email_read_outlined,
                      bg: AppColors.primaryExtralight,
                      iconColor: AppColors.primary,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl2),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _signUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                            style: AppTextStyles.ctaLabel()
                                .copyWith(fontSize: 11, letterSpacing: 2),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.slate200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: AppTextStyles.eyebrow(
                                color: AppColors.slate400)),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.slate200)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SocialButton(
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: 'Continue with Google',
                    onTap: _busy
                        ? null
                        : () => _social(() => ref
                            .read(authRepositoryProvider)
                            .signInWithGoogle()),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _signUp = !_signUp;
                              _error = null;
                              _notice = null;
                            }),
                    child: Text(
                      _signUp
                          ? 'Already have an account? Sign in'
                          : "Don't have an account? Create one",
                      style: AppTextStyles.bodyBold(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.icon,
    required this.bg,
    required this.iconColor,
  });

  final String message;
  final IconData icon;
  final Color bg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyBold(color: AppColors.slate700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.slate200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: const IconThemeData(color: AppColors.primary),
              child: icon,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.bodyBold(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.eyebrow()),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          autocorrect: false,
          enableSuggestions: !obscure,
          style: AppTextStyles.bodyBold(color: AppColors.primary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: suffix,
            enabledBorder: border(AppColors.slate200),
            focusedBorder: border(AppColors.primary, 2),
            errorBorder: border(AppColors.statusAmber),
            focusedErrorBorder: border(AppColors.statusAmber, 2),
          ),
        ),
      ],
    );
  }
}
