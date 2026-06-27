import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportsync/core/theme/app_colors.dart';
import 'package:sportsync/core/theme/app_text_styles.dart';
import 'package:sportsync/features/shell/widgets/floating_header.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Body fills the whole area; screens add their own top inset
          // (Profile/Bookings) or extend full-bleed under the header (Home).
          Positioned.fill(child: navigationShell),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(bottom: false, child: FloatingHeader()),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(navigationShell: navigationShell),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, selected: Icons.home, label: 'HOME'),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      selected: Icons.calendar_today,
      label: 'BOOKINGS',
    ),
    _NavItem(
      icon: Icons.person_outline,
      selected: Icons.person,
      label: 'PROFILE',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.slate100)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = navigationShell.currentIndex == i;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.selected : item.icon,
                      color: active ? AppColors.primary : AppColors.slate400,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: AppTextStyles.microLabel(
                        color: active ? AppColors.primary : AppColors.slate400,
                      ).copyWith(fontSize: 9, letterSpacing: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.label,
  });
  final IconData icon;
  final IconData selected;
  final String label;
}
