import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/core/utils/validators.dart';
import 'package:sportsync/features/profile/data/user_profile_repository.dart';
import 'package:sportsync/features/profile/providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _preferredSport = 'Badminton';
  SkillLevel _skill = SkillLevel.intermediate;
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    if (_hydrated) return;
    _name.text = p.displayName;
    _email.text = p.email;
    _phone.text = p.phone;
    _preferredSport = p.preferredSport;
    _skill = p.skillLevel;
    _hydrated = true;
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save your profile')),
      );
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email (e.g. you@example.com)')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.save(
        UserProfile(
          uid: uid,
          displayName: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          preferredSport: _preferredSport,
          skillLevel: _skill,
          favoriteSport: _preferredSport,
          memberSince: DateTime.now(),
        ),
      );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.asData?.value;
    if (profile != null) _hydrate(profile);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Header(onBack: () => context.pop()),
            const SizedBox(height: 20),
            const _AvatarEditor(),
            const SizedBox(height: 20),
            _TextField(label: 'FULL NAME', controller: _name),
            const SizedBox(height: 16),
            _TextField(
              label: 'EMAIL ADDRESS',
              controller: _email,
              hint: 'Verified',
            ),
            const SizedBox(height: 16),
            _TextField(label: 'PHONE NUMBER', controller: _phone, focused: true),
            const SizedBox(height: 16),
            _SportSelector(
              selected: _preferredSport,
              onChanged: (s) => setState(() => _preferredSport = s),
            ),
            const SizedBox(height: 16),
            _SkillSlider(
              skill: _skill,
              onChanged: (s) => setState(() => _skill = s),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl2),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: AppTextStyles.microLabel(color: AppColors.slate400)
                          .copyWith(fontSize: 10, letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl2),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'SAVE CHANGES',
                            style: AppTextStyles.ctaLabel().copyWith(
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EDIT PROFILE', style: AppTextStyles.headingBlack()),
              const SizedBox(height: 4),
              Text('Update your details',
                  style: AppTextStyles.bodyBold(color: AppColors.slate400)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl3),
                  boxShadow: AppShadows.cta,
                ),
                child: const Icon(Icons.person,
                    color: AppColors.white, size: 48),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: AppColors.primary, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('TAP TO CHANGE PHOTO', style: AppTextStyles.eyebrow()),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.hint,
    this.focused = false,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.eyebrow()),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color:
                focused ? AppColors.primaryExtralight.withValues(alpha: 0.3) : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: focused ? AppColors.primary : AppColors.slate200,
              width: focused ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: AppTextStyles.bodyBold(color: AppColors.primary),
                ),
              ),
              if (hint != null)
                Text(hint!, style: AppTextStyles.eyebrow(color: AppColors.slate300)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SportSelector extends StatelessWidget {
  const _SportSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = ['Badminton', 'Pickleball'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PREFERRED SPORT', style: AppTextStyles.eyebrow()),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final s in _options) ...[
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(s),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected == s ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color:
                            selected == s ? AppColors.primary : AppColors.slate200,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.toUpperCase(),
                      style: AppTextStyles.microLabel(
                        color: selected == s ? AppColors.white : AppColors.slate400,
                      ).copyWith(fontSize: 9, letterSpacing: 1.6),
                    ),
                  ),
                ),
              ),
              if (s != _options.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _SkillSlider extends StatelessWidget {
  const _SkillSlider({required this.skill, required this.onChanged});
  final SkillLevel skill;
  final ValueChanged<SkillLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = SkillLevel.values.indexOf(skill);
    final labels = SkillLevel.values.map((s) => s.label).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SKILL LEVEL', style: AppTextStyles.eyebrow()),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BEGINNER',
                      style: AppTextStyles.microLabel(color: AppColors.primary)
                          .copyWith(fontSize: 10, letterSpacing: 1.8)),
                  Text('PRO',
                      style: AppTextStyles.microLabel(color: AppColors.slate300)
                          .copyWith(fontSize: 10, letterSpacing: 1.8)),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.slate100,
                  thumbColor: AppColors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 2,
                    pressedElevation: 4,
                  ),
                ),
                child: Slider(
                  min: 0,
                  max: (SkillLevel.values.length - 1).toDouble(),
                  divisions: SkillLevel.values.length - 1,
                  value: index.toDouble(),
                  onChanged: (v) => onChanged(SkillLevel.values[v.round()]),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[index].toUpperCase(),
                  style: AppTextStyles.pill().copyWith(letterSpacing: 1.6)),
            ],
          ),
        ),
      ],
    );
  }
}
