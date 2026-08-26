import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_model.dart';
import '../models/battle_state.dart';
import '../models/focus_session.dart';
import '../providers/battle_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/create_battle_modal.dart';
import '../widgets/doodle_decorations.dart';
import '../widgets/join_battle_modal.dart';
import 'focus_screen.dart';

class BattlesScreen extends StatelessWidget {
  const BattlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final battleProvider = context.watch<BattleProvider>();
    final asyncBattles = timerProvider.battles;
    final guestBattles = battleProvider.localBattleHistory;

    final hasAnyBattles = asyncBattles.isNotEmpty || guestBattles.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FOCUS BATTLES', style: AppTheme.sansLabel()),
                      const SizedBox(height: 4),
                      Text(
                        'Friendly accountability.',
                        style: AppTheme.serifHeading(fontSize: 26),
                      ),
                    ],
                  ),
                  const SparkleDoodle(size: 24, color: AppTheme.ink),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Focus alongside friends with live accountability. No account required.',
                style: AppTheme.sansBody(
                  fontSize: 14,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Live 1v1 Guest Battle Action Cards
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => CreateBattleModal.show(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.sand,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.ink, width: 1.5),
                          boxShadow: AppTheme.smallTactileShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.peach,
                                border: Border.all(
                                  color: AppTheme.ink,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Create Battle',
                              style: AppTheme.serifHeading(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Get room code',
                              style: AppTheme.sansBody(
                                fontSize: 12,
                                color: AppTheme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => JoinBattleModal.show(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.sand,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.ink, width: 1.5),
                          boxShadow: AppTheme.smallTactileShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.sage,
                                border: Border.all(
                                  color: AppTheme.ink,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.login,
                                size: 18,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Join Battle',
                              style: AppTheme.serifHeading(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter 6-char code',
                              style: AppTheme.sansBody(
                                fontSize: 12,
                                color: AppTheme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 16),

              Text('BATTLE HISTORY', style: AppTheme.sansLabel(fontSize: 11)),
              const SizedBox(height: 12),

              if (!hasAnyBattles)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        const LockInLogo(size: 44, hasBorder: true),
                        const SizedBox(height: 16),
                        Text(
                          'No battles recorded yet.',
                          style: AppTheme.serifHeading(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a room or enter an invite code to duel a friend.',
                          textAlign: TextAlign.center,
                          style: AppTheme.sansBody(color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Render real-time Guest Battles
                ...guestBattles.map(
                  (battle) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _GuestBattleCard(battle: battle),
                  ),
                ),

                // Render async battles for backwards compatibility
                ...asyncBattles.map(
                  (battle) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _BattleCard(battle: battle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestBattleCard extends StatelessWidget {
  final BattleSessionModel battle;

  const _GuestBattleCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final opponent = battle.participants.length > 1
        ? battle.participants.last
        : battle.participants.firstOrNull;

    final opponentName = opponent?.displayName ?? 'Opponent';
    final initial = opponentName.isNotEmpty
        ? opponentName[0].toUpperCase()
        : '?';
    final isComplete = battle.status == BattleStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ink, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.sand,
              border: Border.all(color: AppTheme.ink, width: 1.2),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTheme.serifHeading(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1v1 with $opponentName',
                  style: AppTheme.sansBody(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${battle.durationMinutes} min · Room ${battle.roomCode}',
                  style: AppTheme.sansBody(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isComplete ? AppTheme.sage : AppTheme.sand,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.ink, width: 1),
            ),
            child: Text(
              isComplete ? 'FINISHED' : 'SAVED',
              style: AppTheme.sansLabel(
                fontSize: 9,
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  final BattleModel battle;

  const _BattleCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final total = (battle.userMinutes + battle.opponentMinutes);
    final userRatio = total > 0 ? (battle.userMinutes / total) : 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ink, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.sand,
                  border: Border.all(color: AppTheme.ink, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    battle.opponentInitials,
                    style: AppTheme.serifHeading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battle with ${battle.opponentName}',
                      style: AppTheme.sansBody(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      battle.isUserAhead
                          ? "You're ahead · ${battle.endsIn}"
                          : "Behind by ${(battle.opponentMinutes - battle.userMinutes)}m · ${battle.endsIn}",
                      style: AppTheme.sansBody(
                        fontSize: 12,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                battle.scoreComparison,
                style: AppTheme.serifHeading(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'You: ${battle.userMinutes}m',
                    style: AppTheme.sansLabel(
                      fontSize: 11,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    '${battle.opponentName}: ${battle.opponentMinutes}m',
                    style: AppTheme.sansLabel(
                      fontSize: 11,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.ink, width: 1.2),
                  color: AppTheme.sand,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (userRatio * 100).toInt().clamp(1, 99),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.ink,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1.0 - userRatio) * 100).toInt().clamp(1, 99),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.peach,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          TactileButton(
            label: 'Enter battle focus',
            height: 48,
            fontSize: 14,
            fillColor: AppTheme.peach,
            onTap: () {
              context.read<TimerProvider>().startSession(
                minutes: 45,
                type: SessionType.battle,
                battle: battle,
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FocusScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
