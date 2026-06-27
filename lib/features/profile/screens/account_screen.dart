import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/core/utils/validators.dart';
import 'package:sportsync/features/auth/data/auth_repository.dart';
import 'package:sportsync/features/profile/providers/profile_providers.dart';

const _danger = Color(0xFFDC2626);

/// Account management for a signed-in (non-anonymous) user: email verification,
/// change password, and delete account. Reached from Profile → ACCOUNT.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _pwFormKey = GlobalKey<FormState>();
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  bool _busyPw = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _changePassword() async {
    if (!(_pwFormKey.currentState?.validate() ?? false)) return;
    setState(() => _busyPw = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentPw.text,
            newPassword: _newPw.text,
          );
      _currentPw.clear();
      _newPw.clear();
      _snack('Password updated.');
    } on AuthException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyPw = false);
    }
  }

  Future<void> _resendVerification() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      _snack('Verification email sent — check your inbox.');
    } on AuthException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _refreshVerified() async {
    await ref.read(authRepositoryProvider).reloadUser();
    if (mounted) setState(() {});
  }

  Future<void> _deleteAccount() async {
    final password = await _promptPassword();
    if (password == null) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount(password);
      if (mounted) {
        _snack('Your account has been deleted.');
        context.pop();
      }
    } on AuthException catch (e) {
      _snack(e.message);
    }
  }

  /// Confirm destructive delete by re-entering the password.
  Future<String?> _promptPassword() {
    final ctrl = TextEditingController();
    var obscure = true;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your account. Enter your password to '
                'confirm. You can keep using the app as a guest afterwards.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _danger),
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('DELETE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final email = user?.email ?? '';
    final verified = user?.emailVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Header(onBack: () => context.pop()),
            const SizedBox(height: 20),

            // Email + verification status
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMAIL', style: AppTextStyles.eyebrow()),
                  const SizedBox(height: 6),
                  Text(
                    email.isEmpty ? '—' : email,
                    style: AppTextStyles.bodyBold(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  if (verified)
                    Row(
                      children: [
                        const Icon(Icons.verified,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Verified',
                            style: AppTextStyles.bodyBold(
                                color: AppColors.primary)),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.statusAmber),
                        const SizedBox(width: 6),
                        Text('Not verified',
                            style: AppTextStyles.bodyBold(
                                color: AppColors.statusAmber)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _resendVerification,
                          child: const Text('RESEND EMAIL'),
                        ),
                        TextButton(
                          onPressed: _refreshVerified,
                          child: const Text("I'VE VERIFIED"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Change password
            _Card(
              child: Form(
                key: _pwFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHANGE PASSWORD', style: AppTextStyles.eyebrow()),
                    const SizedBox(height: 12),
                    _PwField(
                      hint: 'Current password',
                      controller: _currentPw,
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _PwField(
                      hint: 'New password',
                      controller: _newPw,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: passwordFieldValidator,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busyPw ? null : _changePassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl2),
                          ),
                        ),
                        child: _busyPw
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('UPDATE PASSWORD',
                                style: AppTextStyles.ctaLabel()
                                    .copyWith(fontSize: 11, letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delete account (danger)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DANGER ZONE',
                      style: AppTextStyles.eyebrow(color: _danger)),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently delete your account and profile. This cannot '
                    'be undone.',
                    style: AppTextStyles.bodyBold(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _danger,
                        side: const BorderSide(color: _danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl2),
                        ),
                      ),
                      child: Text('DELETE ACCOUNT',
                          style: AppTextStyles.ctaLabel(color: _danger)
                              .copyWith(fontSize: 11, letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.slate100),
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.primary, size: 14),
          ),
        ),
        const SizedBox(width: 12),
        Text('ACCOUNT', style: AppTextStyles.headingBlack()),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(color: AppColors.slate100),
      ),
      child: child,
    );
  }
}

class _PwField extends StatelessWidget {
  const _PwField({
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autocorrect: false,
      enableSuggestions: false,
      style: AppTextStyles.bodyBold(color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 18, color: AppColors.slate400),
          onPressed: onToggle,
        ),
        enabledBorder: border(AppColors.slate200),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(AppColors.statusAmber),
        focusedErrorBorder: border(AppColors.statusAmber, 2),
      ),
    );
  }
}
