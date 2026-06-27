import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_radius.dart';
import 'package:sportsync/core/theme/app_shadows.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/auth/data/auth_repository.dart';
import 'package:sportsync/features/auth/widgets/auth_sheet.dart';
import 'package:sportsync/features/bookings/providers/bookings_providers.dart';
import 'package:sportsync/features/profile/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).asData?.value;
    // Anonymous users are signed in to Firebase but have no real account, so
    // treat them as signed-out for the UI.
    final signedIn = auth != null && !auth.isAnonymous;
    final profileAsync = ref.watch(userProfileProvider);
    final stats = ref.watch(bookingsStatsProvider);

    final profile = profileAsync.asData?.value;
    final displayName = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : (auth?.displayName ?? 'Guest');
    final email = (profile?.email.isNotEmpty ?? false)
        ? profile!.email
        : (auth?.email ?? '');
    final favoriteSport = profile?.favoriteSport ?? 'Badminton';
    final memberYear = (profile?.memberSince ?? DateTime.now()).year;

    return Container(
      color: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 64,
          16,
          32,
        ),
        children: [
          _IdentityCard(
            displayName: displayName,
            email: email,
            memberYear: memberYear,
            onEdit: () => context.push('/profile/edit'),
          ),
          if (signedIn && !auth.emailVerified) ...[
            const SizedBox(height: 12),
            const _VerifyBanner(),
          ],
          const SizedBox(height: 16),
          _StatsRow(
            bookings: stats.total,
            hours: stats.hours,
            rating: stats.rating,
          ),
          const SizedBox(height: 16),
          _FavoriteSportCard(sport: favoriteSport),
          const SizedBox(height: 16),
          _MenuList(),
          if (signedIn) ...[
            const SizedBox(height: 16),
            const _AccountButton(),
          ],
          const SizedBox(height: 16),
          signedIn ? const _SignOutButton() : const _SignInButton(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'SPORTSYNC v1.0  ·  DAVAO',
              style: AppTextStyles.eyebrow(color: AppColors.slate300)
                  .copyWith(letterSpacing: 3.6, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.displayName,
    required this.email,
    required this.memberYear,
    required this.onEdit,
  });

  final String displayName;
  final String email;
  final int memberYear;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(color: AppColors.slate100),
        boxShadow: AppShadows.cardSubtle,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl2),
                  boxShadow: AppShadows.cta,
                ),
                child: const Icon(Icons.person,
                    color: AppColors.white, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEMBER SINCE $memberYear',
                      style: AppTextStyles.eyebrow(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName.isEmpty ? 'Guest' : displayName,
                      style: AppTextStyles.cardTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: AppTextStyles.bodyBold(color: AppColors.slate500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: AppColors.primary, size: 14),
                ),
              ),
            ],
          ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.bookings,
    required this.hours,
    required this.rating,
  });
  final int bookings;
  final int hours;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(icon: Icons.calendar_month, value: '$bookings', label: 'BOOKINGS'),
        const SizedBox(width: 8),
        _StatTile(icon: Icons.access_time, value: '${hours}h', label: 'PLAYED'),
        const SizedBox(width: 8),
        _StatTile(
          icon: Icons.star,
          value: NumberFormat('0.0').format(rating),
          label: 'RATING',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.statNumber()),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.microLabel()),
          ],
        ),
      ),
    );
  }
}

class _FavoriteSportCard extends StatelessWidget {
  const _FavoriteSportCard({required this.sport});
  final String sport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        boxShadow: AppShadows.cta,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.bolt, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAVORITE SPORT',
                  style: AppTextStyles.eyebrow(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sport.toUpperCase(),
                  style: AppTextStyles.pageTitle(color: AppColors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'CHANGE',
              style: AppTextStyles.microLabel(color: AppColors.white)
                  .copyWith(fontSize: 9, letterSpacing: 1.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.favorite_outline, 'SAVED COURTS', '5', null),
      (Icons.credit_card, 'PAYMENT METHODS', 'QR Ph', null),
      (Icons.notifications_outlined, 'NOTIFICATIONS', 'On', null),
      (Icons.help_outline, 'HELP & SUPPORT', 'About', '/profile/about'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuRow(
              icon: items[i].$1,
              label: items[i].$2,
              trail: items[i].$3,
              onTap: () {
                final route = items[i].$4;
                if (route != null) {
                  context.push(route);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                }
              },
            ),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.slate100,
                indent: 0,
                endIndent: 0,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.trail,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String? trail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryExtralight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.pill()),
            ),
            if (trail != null) ...[
              Text(trail!, style: AppTextStyles.eyebrow()),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right,
                color: AppColors.slate300, size: 16),
          ],
        ),
      ),
    );
  }
}

class _VerifyBanner extends ConsumerWidget {
  const _VerifyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.statusAmberBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              size: 16, color: AppColors.statusAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verify your email to secure your account.',
              style: AppTextStyles.bodyBold(color: AppColors.slate700),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(authRepositoryProvider).sendEmailVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Verification email sent.')),
                  );
                }
              } on AuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: Text('RESEND',
                style: AppTextStyles.microLabel(color: AppColors.primary)
                    .copyWith(fontSize: 10, letterSpacing: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/profile/account'),
      borderRadius: BorderRadius.circular(AppRadius.xl3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl3),
          border: Border.all(color: AppColors.slate100),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryExtralight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.manage_accounts_outlined,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('ACCOUNT & SECURITY', style: AppTextStyles.pill()),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.slate300, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AuthSheet.show(context),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.cta,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 14, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              'SIGN IN / CREATE ACCOUNT',
              style: AppTextStyles.ctaLabel()
                  .copyWith(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends ConsumerStatefulWidget {
  const _SignOutButton();

  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool _busy = false;

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can keep browsing and booking as a guest after signing out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _busy ? null : _confirmAndSignOut,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_busy)
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.slate400,
                ),
              )
            else
              const Icon(Icons.logout, size: 14, color: AppColors.slate400),
            const SizedBox(width: 8),
            Text(
              _busy ? 'SIGNING OUT…' : 'SIGN OUT',
              style: AppTextStyles.microLabel(color: AppColors.slate400)
                  .copyWith(fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
