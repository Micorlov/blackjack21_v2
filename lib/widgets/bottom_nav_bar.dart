import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class _NavItem {
  final AppScreen screen;
  final IconData icon;
  final String label;
  const _NavItem(this.screen, this.icon, this.label);
}

const List<_NavItem> _kNavItems = [
  _NavItem(AppScreen.lobby, Icons.diamond_rounded, 'Lobby'),
  _NavItem(AppScreen.stats, Icons.bar_chart_rounded, 'Stats'),
  _NavItem(AppScreen.friends, Icons.people_alt_rounded, 'Friends'),
  _NavItem(AppScreen.shop, Icons.storefront_rounded, 'Shop'),
  _NavItem(AppScreen.settings, Icons.tune_rounded, 'Settings'),
];

class AppBottomNavBar extends StatelessWidget {
  final AppScreen current;
  final ValueChanged<AppScreen> onSelect;

  const AppBottomNavBar({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.shellBlack.withValues(alpha: AppAlpha.scrim),
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 14),
          // The app shell draws edge-to-edge, so the system navigation bar
          // (gesture pill or the three-button row) is painted on top of this
          // widget. Insetting the content — and not the container — keeps the
          // blurred background bleeding to the screen edge while the icons and
          // labels stay clear of the system bar instead of under it.
          child: SafeArea(
            top: false,
            child: Row(
              children: _kNavItems.map((item) {
                final active = current == item.screen;
                final color = active ? AppColors.gold : AppColors.textFaint;
                return Expanded(
                  // `selected` is what makes a screen reader say "Lobby, tab,
                  // selected" rather than five identical-sounding buttons.
                  // Sighted players get that from the gold tint; without this
                  // the state was carried by colour alone.
                  child: Semantics(
                    button: true,
                    selected: active,
                    label: item.label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onSelect(item.screen),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon, color: color, size: 27),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: AppText.sora(13, weight: FontWeight.w700, color: color),
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
        ),
      ),
    );
  }
}
