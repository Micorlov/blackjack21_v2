import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_state.dart';
import '../../state/game_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/flags.dart';
import '../../utils/formatters.dart';
import '../../utils/world_standings.dart';
import '../../widgets/panel_card.dart';

/// Full "see all players" view pushed from the betting panel's mini
/// standings card — same FRIENDS / WORLD · THIS HOUR / WORLD · TODAY pages,
/// uncapped, with a flag per row.
class WorldLeaderboardScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const WorldLeaderboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<WorldLeaderboardScreen> createState() => _WorldLeaderboardScreenState();
}

class _WorldLeaderboardScreenState extends ConsumerState<WorldLeaderboardScreen> {
  static const List<String> _titles = ['Friends', 'World · this hour', 'World · today'];

  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(child: ScreenTitle('Standings')),
                ],
              ),
              Row(
                children: [
                  for (var i = 0; i < _titles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _TabPill(label: _titles[i], active: _tab == i, onTap: () => setState(() => _tab = i)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (_tab == 0)
                _friendsSection(s, notifier)
              else
                _StandingsList(rows: worldStandings(s, hourly: _tab == 1, minCount: 5).rows),
            ],
          ),
        ),
      ),
    );
  }

  Widget _friendsSection(GameState s, GameNotifier notifier) {
    if (!s.friendsAreLive) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              'No friends here yet — you play alone.',
              textAlign: TextAlign.center,
              style: AppText.sora(14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: notifier.shareInviteWhatsApp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  'Invite friends on WhatsApp',
                  style: AppText.sora(14, weight: FontWeight.w800, color: AppColors.goldInk),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _StandingsList(rows: friendsStandingsRows(s));
  }
}

class _StandingsList extends StatelessWidget {
  final List<StandingsRow> rows;

  const _StandingsList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${i + 1}',
                      style: AppText.mono(
                        13,
                        weight: FontWeight.w700,
                        color: i == 0 ? AppColors.gold : AppColors.textFaint,
                      ),
                    ),
                  ),
                  Text(flagForId(rows[i].id), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sora(
                        15,
                        weight: rows[i].isSelf ? FontWeight.w800 : FontWeight.w600,
                        color: rows[i].isSelf ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${rows[i].points >= 0 ? '+' : '-'}\$${formatChips(rows[i].points.abs())}',
                    style: AppText.mono(
                      14,
                      weight: FontWeight.w700,
                      color: rows[i].points >= 0 ? AppColors.winLight : AppColors.loseSoft,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Local copy of friends_screen.dart's `_TabPill` — kept private to each
/// screen since the two aren't otherwise coupled.
class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? AppColors.gold : AppColors.border),
              color: active ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
            ),
            child: Text(
              label,
              style: AppText.sora(13, weight: FontWeight.w700, color: active ? AppColors.gold : AppColors.textFaint),
            ),
          ),
        ),
      ),
    );
  }
}
