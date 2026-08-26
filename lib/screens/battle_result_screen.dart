import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/battle_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';

class BattleResultScreen extends StatelessWidget {
  const BattleResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();
    final result = battleProvider.lastResult;

    final isWin = result?.isLocalWinner ?? false;
    final isDraw = result?.isDraw ?? false;
    final isForfeit = result?.isForfeit ?? false;
    final opponentName = result?.opponentParticipant.displayName ?? 'Opponent';

    String headline;
    String subtext;
    Color badgeColor;

    if (isDraw) {
      headline = 'Battle Tied.';
      subtext = 'Both players completed the full focus block unbroken.';
      badgeColor = AppTheme.sand;
    } else if (isWin) {
      headline = 'Victory.';
      subtext = isForfeit
          ? '$opponentName conceded early. You stayed locked in!'
          : 'You completed your focus block and won the duel.';
      badgeColor = AppTheme.sage;
    } else {
      headline = 'Defeat.';
      subtext = isForfeit
          ? 'You left the session early.'
          : '$opponentName held focus longer this round.';
      badgeColor = const Color(0xFFFBEBE8);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dismiss/Close logo button
              GestureDetector(
                onTap: () {
                  battleProvider.resetBattle();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.ink, width: 1.5),
                    boxShadow: AppTheme.smallTactileShadow,
                  ),
                  child: Center(
                    child: Icon(
                      isWin
                          ? Icons.emoji_events_outlined
                          : (isDraw ? Icons.handshake_outlined : Icons.close),
                      size: 24,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Result Headline
              Text(
                headline,
                style: AppTheme.serifHeading(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtext,
                style: AppTheme.sansBody(
                  fontSize: 14,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 24),

              // Match Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.sand,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.ink, width: 1.5),
                  boxShadow: AppTheme.tactileShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MATCH STATS',
                          style: AppTheme.sansLabel(fontSize: 10),
                        ),
                        Text(
                          'Room: ${result?.roomCode ?? "------"}',
                          style: AppTheme.sansLabel(
                            fontSize: 10,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _PlayerSummaryColumn(
                          name:
                              '${result?.localParticipant.displayName ?? "You"} (You)',
                          isWinner: isWin,
                          isForfeited: isForfeit && !isWin,
                        ),
                        Text(
                          'VS',
                          style: AppTheme.serifHeading(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                        _PlayerSummaryColumn(
                          name: opponentName,
                          isWinner: !isWin && !isDraw,
                          isForfeited: isForfeit && isWin,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Guest note
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.inkFaint, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppTheme.ink,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Battle recorded in your local history.',
                        style: AppTheme.sansBody(
                          fontSize: 12,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Done Button
              TactileButton(
                label: 'Return to Home',
                fillColor: AppTheme.ink,
                textColor: AppTheme.background,
                height: 52,
                fontSize: 15,
                onTap: () {
                  battleProvider.resetBattle();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSummaryColumn extends StatelessWidget {
  final String name;
  final bool isWinner;
  final bool isForfeited;

  const _PlayerSummaryColumn({
    required this.name,
    required this.isWinner,
    required this.isForfeited,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: AppTheme.sansBody(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner
                ? AppTheme.sage
                : (isForfeited ? const Color(0xFFFBEBE8) : AppTheme.background),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.ink, width: 1),
          ),
          child: Text(
            isWinner ? 'WINNER' : (isForfeited ? 'FORFEIT' : 'FINISHED'),
            style: AppTheme.sansLabel(
              fontSize: 9,
              color: isForfeited ? AppTheme.errorMuted : AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
