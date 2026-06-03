import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';

/// Main shell with a floating "liquid glass" bottom tab bar.
class MainShellScreen extends StatefulWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Surah',
    ),
    _NavItem(
      icon: Icons.headphones_outlined,
      activeIcon: Icons.headphones,
      label: 'Stories',
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Trivia',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  final List<String> _routes = [
    AppRoutes.home,
    AppRoutes.surahs,
    AppRoutes.stories,
    AppRoutes.practice,
    AppRoutes.profile,
  ];

  // Active tab is derived from the current route so navigating here from
  // anywhere (e.g. tapping the profile avatar) keeps the bar in sync.
  int get _currentIndex {
    final loc = GoRouterState.of(context).uri.toString();
    final i = _routes.indexWhere((r) => loc.startsWith(r));
    return i < 0 ? 0 : i;
  }

  void _onTap(int index) {
    if (index != _currentIndex) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.35),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 2,
                    spreadRadius: -1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glassy inner highlight at the top edge
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.8),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_items.length, (i) {
                      final item = _items[i];
                      final active = i == _currentIndex;
                      return _NavButton(
                        item: item,
                        active: active,
                        onTap: () => _onTap(i),
                      );
                    }),
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

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.softGold.withValues(alpha: 0.45)
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color:
                              AppColors.metallicGold.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  key: ValueKey(active),
                  size: 22,
                  color: active
                      ? AppColors.heroBlack
                      : AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color:
                    active ? AppColors.textPrimary : AppColors.textTertiary,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
