import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_model.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'focus_screen.dart';

class BattlesScreen extends StatelessWidget {
  const BattlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final battles = provider.battles;

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
                  IconButton(
                    onPressed: () => _showNewBattleDialog(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.ink, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: AppTheme.ink,
                      ),
                    ),
                    tooltip: 'New battle',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Focus alongside friends. Compare your deep work time without noise or pressure.',
                style: AppTheme.sansBody(
                  fontSize: 14,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 24),

              if (battles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        const LockInLogo(size: 44, hasBorder: true),
                        const SizedBox(height: 16),
                        Text(
                          'No active battles yet.',
                          style: AppTheme.serifHeading(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start a friendly duel with a coworker or friend.',
                          style: AppTheme.sansBody(color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 20),
                        TactileButton(
                          label: 'Invite a Friend',
                          isFullWidth: false,
                          onTap: () => _showNewBattleDialog(context),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...battles.map(
                  (battle) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _BattleCard(battle: battle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewBattleDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedHours = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.ink, width: 1.5),
          ),
          title: Text(
            'New Focus Battle',
            style: AppTheme.serifHeading(fontSize: 22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Opponent name', style: AppTheme.sansLabel()),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: AppTheme.sansBody(),
                decoration: InputDecoration(
                  hintText: 'e.g. Maya, Sam, Liam',
                  hintStyle: AppTheme.sansBody(color: AppTheme.inkLight),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.ink,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.ink,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Target battle window', style: AppTheme.sansLabel()),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final h in [2, 4, 8])
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedHours = h),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selectedHours == h
                                ? AppTheme.ink
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedHours == h
                                  ? AppTheme.ink
                                  : AppTheme.inkFaint,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            '${h}h',
                            style: AppTheme.sansBody(
                              fontSize: 13,
                              fontWeight: selectedHours == h
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selectedHours == h
                                  ? AppTheme.background
                                  : AppTheme.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: AppTheme.sansBody(color: AppTheme.inkMuted),
              ),
            ),
            TactileButton(
              label: 'Create Battle',
              isFullWidth: false,
              height: 44,
              fontSize: 14,
              onTap: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<TimerProvider>().createBattle(
                    name,
                    selectedHours,
                  );
                  Navigator.pop(dialogCtx);
                }
              },
            ),
          ],
        ),
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
          // Header: Avatar, Name, Status, Score
          Row(
            children: [
              // Doodle-style avatar circle
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

          // Comparison progress bar
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
              // Dual-ratio outlined comparison bar
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

          // Primary action
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
