import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/core/utils/validators.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';
import 'package:sportsync/features/profile/data/user_profile_repository.dart';
import 'package:sportsync/features/profile/providers/profile_providers.dart';

/// Shows the "Your Details" form used by the booking flow to collect the
/// name / email / phone shown on the booking + receipt.
///
/// Returns `true` if the user submitted, `false`/`null` if they cancelled.
/// For signed-in (non-anonymous) users the submitted details are merged into
/// their Firestore profile (`users/{uid}`) so they autofill next time and stay
/// editable from the Profile tab. Guests just keep them for this booking.
Future<bool?> showUserFormModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _UserFormDialog(),
  );
}

class _UserFormDialog extends ConsumerStatefulWidget {
  const _UserFormDialog();

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Seeded by the payment step from the signed-in user's profile (if any).
    _nameCtrl = TextEditingController(text: ref.read(userNameProvider));
    _emailCtrl = TextEditingController(text: ref.read(userEmailProvider));
    _phoneCtrl = TextEditingController(text: ref.read(userPhoneProvider));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    ref.read(userNameProvider.notifier).state = name;
    ref.read(userEmailProvider.notifier).state = email;
    ref.read(userPhoneProvider.notifier).state = phone;

    // Signed-in (non-anonymous) users: persist to their Firestore profile so
    // the details autofill next time and stay editable from the Profile tab.
    final auth = ref.read(authStateProvider).asData?.value;
    final uid = ref.read(currentUidProvider);
    if (auth != null && !auth.isAnonymous && uid != null) {
      try {
        await ref.read(userProfileRepositoryProvider).merge(
              uid,
              displayName: name,
              email: email,
              phone: phone,
            );
      } catch (_) {
        // Non-fatal — the in-flight booking still has what it needs.
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Details', style: AppTextStyles.cardTitle()),
              const SizedBox(height: 6),
              Text(
                "We'll use these for your booking confirmation.",
                style: AppTextStyles.bodyBold(color: AppColors.slate500),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'FULL NAME',
                controller: _nameCtrl,
                hint: 'Juan dela Cruz',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'EMAIL ADDRESS',
                controller: _emailCtrl,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: emailFieldValidator,
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'PHONE NUMBER (OPTIONAL)',
                controller: _phoneCtrl,
                hint: '+63 912 345 6789',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.slate200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'CANCEL',
                        style:
                            AppTextStyles.microLabel(color: AppColors.slate400)
                                .copyWith(fontSize: 10, letterSpacing: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl2),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'COMPLETE',
                              style: AppTextStyles.ctaLabel()
                                  .copyWith(fontSize: 10, letterSpacing: 2),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand form field: uppercase eyebrow label above a rounded, focus-aware
/// container. Mirrors the field pattern in `edit_profile_screen.dart`.
class _LabeledField extends StatefulWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _focused) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.eyebrow(
            color: _focused ? AppColors.primary : AppColors.slate400,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          style: AppTextStyles.bodyBold(color: AppColors.slate800)
              .copyWith(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _focused
                ? AppColors.primaryExtralight.withValues(alpha: 0.3)
                : AppColors.white,
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyBold(color: AppColors.slate300)
                .copyWith(fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _border(AppColors.slate200, 1),
            enabledBorder: _border(AppColors.slate200, 1),
            focusedBorder: _border(AppColors.primary, 2),
            errorBorder: _border(errorColor, 1),
            focusedErrorBorder: _border(errorColor, 2),
          ),
        ),
      ],
    );
  }
}
