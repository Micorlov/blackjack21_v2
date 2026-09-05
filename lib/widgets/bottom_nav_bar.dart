import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _NavItem {
  final AppScreen screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.screen, this.icon, this.activeIcon, this.label);
}

/// Four destinations. The shop tab went with the shop; four is also the most
/// a bottom bar comfortably labels on a 320-wide phone.
const List<_NavItem> _kNavItems = [
  _NavItem(AppScreen.lobby, Icons.home_outlined, Icons.home_rounded, 'Home'),
  _NavItem(AppScreen.stats, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
  _NavItem(AppScreen.friends, Icons.people_outline_rounded, Icons.people_rounded, 'Friends'),
  _NavItem(AppScreen.settings, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
];

/// A flat, opaque bar. The old one blurred whatever scrolled beneath it and
/// lit the active tab in gold at 27px — the loudest element on every screen,
/// for the one control the player uses least.
class AppBottomNavBar extends StatelessWidget {
  final AppScreen current;
  final ValueChanged<AppScreen> onSelect;

  const AppBottomNavBar({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      // The app shell draws edge-to-edge, so the system navigation bar is
      // painted on top of this widget. Insetting the content — and not the
      // container — keeps the bar's colour bleeding to the screen edge while
      // the icons and labels stay clear of the system bar.
      child: SafeArea(
        top: false,
        child: Row(
          children: _kNavItems.map((item) {
            final active = current == item.screen;
            final color = active ? AppColors.textPrimary : AppColors.textFaint;
            return Expanded(
              // `selected` is what makes a screen reader say "Home, tab,
              // selected" rather than four identical-sounding buttons.
              child: Semantics(
                button: true,
                selected: active,
                label: item.label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(item.screen),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(active ? item.activeIcon : item.icon, color: color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppText.sora(12, weight: active ? FontWeight.w700 : FontWeight.w600, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
