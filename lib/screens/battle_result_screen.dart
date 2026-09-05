import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_state.dart';
import '../providers/battle_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'battle_focus_screen.dart';

class BattleResultScreen extends StatelessWidget {
  const BattleResultScreen({super.key});

  void _returnToHome(BuildContext context, BattleProvider battleProvider) {
    context.read<TimerProvider>().refreshFromStorage();
    battleProvider.resetBattle();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();
    final result = battleProvider.lastResult;

    final isWin = result?.isLocalWinner ?? false;
    final isDraw = result?.isDraw ?? false;
    final isForfeit = result?.isForfeit ?? false;
    final opponentName = result?.opponentParticipant.displayName ?? 'Opponent';

    // If battle was extended (e.g. by host, or received on guest), return to focus screen
    if (battleProvider.status == BattleStatus.active) {
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BattleFocusScreen()),
        );
      });
    }

    String headline;
    String subtext;
    Color badgeColor;

    if (isDraw) {
      headline = 'Battle Tied.';
      subtext = 'Both players completed the full focus block unbroken.';
      badgeColor = AppTheme.sandColor(context);
    } else if (isWin) {
      headline = 'Victory.';
      subtext = isForfeit
          ? '$opponentName conceded early. You stayed locked in!'
          : 'You completed your focus block and won the duel.';
      badgeColor = AppTheme.sageColor(context);
    } else {
      headline = 'Defeat.';
      subtext = isForfeit
          ? 'You left the session early.'
          : '$opponentName held focus longer this round.';
      badgeColor = AppTheme.isDark(context)
          ? const Color(0xFF381E1C)
          : const Color(0xFFFBEBE8);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _returnToHome(context, battleProvider);
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dismiss/Close logo button
                GestureDetector(
                  onTap: () => _returnToHome(context, battleProvider),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
                      boxShadow: AppTheme.smallShadow(context),
                    ),
                    child: Center(
                      child: Icon(
                        isWin
                            ? Icons.emoji_events_outlined
                            : (isDraw ? Icons.handshake_outlined : Icons.close),
                        size: 24,
                        color: AppTheme.text(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Result Headline
                Text(
                  headline,
                  style: AppTheme.serifHeading(
                    context: context,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtext,
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 14,
                    color: AppTheme.muted(context),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),
                Divider(color: AppTheme.faint(context), thickness: 1),
                const SizedBox(height: 24),

                // Match Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.sandColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
                    boxShadow: AppTheme.shadow(context),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MATCH STATS',
                            style: AppTheme.sansLabel(context: context, fontSize: 10),
                          ),
                          Text(
                            'Room: ${result?.roomCode ?? "------"}',
                            style: AppTheme.sansLabel(
                              context: context,
                              fontSize: 10,
                              color: AppTheme.muted(context),
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
                              context: context,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.muted(context),
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
                    color: AppTheme.bg(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.faint(context), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppTheme.inkColor(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Battle recorded in your local history.',
                          style: AppTheme.sansBody(
                            context: context,
                            fontSize: 12,
                            color: AppTheme.muted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Extend Session Card (Host only - identical to solo focus)
                if (battleProvider.isHost) ...[
                  const SizedBox(height: 20),
                  _ExtendSessionCard(
                    onExtend: (minutes) {
                      battleProvider.extendBattle(minutes);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BattleFocusScreen(),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.sandColor(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        SparkleDoodle(size: 16, color: AppTheme.inkColor(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Waiting for host... host can extend the session.',
                            style: AppTheme.sansBody(
                              context: context,
                              fontSize: 12,
                              color: AppTheme.muted(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Primary Done Button
                TactileButton(
                  label: 'Return to Home',
                  fillColor: AppTheme.inkColor(context),
                  textColor: AppTheme.bg(context),
                  height: 52,
                  fontSize: 15,
                  onTap: () => _returnToHome(context, battleProvider),
                ),
                const SizedBox(height: 16),
              ],
            ),
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
          style: AppTheme.sansBody(
            context: context,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner
                ? AppTheme.sageColor(context)
                : (isForfeited
                    ? (AppTheme.isDark(context)
                        ? const Color(0xFF381E1C)
                        : const Color(0xFFFBEBE8))
                    : AppTheme.bg(context)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inkColor(context), width: 1),
          ),
          child: Text(
            isWinner ? 'WINNER' : (isForfeited ? 'FORFEIT' : 'FINISHED'),
            style: AppTheme.sansLabel(
              context: context,
              fontSize: 9,
              color: isForfeited ? AppTheme.error(context) : AppTheme.text(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExtendSessionCard extends StatefulWidget {
  final ValueChanged<int> onExtend;

  const _ExtendSessionCard({required this.onExtend});

  @override
  State<_ExtendSessionCard> createState() => _ExtendSessionCardState();
}

class _ExtendSessionCardState extends State<_ExtendSessionCard> {
  int _extensionMinutes = 5;

  void _decrement() {
    setState(() {
      if (_extensionMinutes > 5) {
        _extensionMinutes -= 5;
      } else if (_extensionMinutes > 1) {
        _extensionMinutes = 1;
      }
    });
  }

  void _increment() {
    setState(() {
      if (_extensionMinutes == 1) {
        _extensionMinutes = 5;
      } else if (_extensionMinutes <= 115) {
        _extensionMinutes += 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
        boxShadow: AppTheme.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SparkleDoodle(size: 14, color: AppTheme.inkColor(context)),
                  const SizedBox(width: 8),
                  Text(
                    'EXTEND SESSION',
                    style: AppTheme.sansLabel(
                      context: context,
                      fontSize: 11,
                      color: AppTheme.text(context),
                    ),
                  ),
                ],
              ),
              Text(
                'Keep momentum rolling',
                style: AppTheme.sansBody(
                  context: context,
                  fontSize: 11,
                  color: AppTheme.muted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper Row: [-] [ +5 min ] [+]
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                enabled: _extensionMinutes > 1,
                onTap: _decrement,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '+$_extensionMinutes min',
                    style: AppTheme.serifHeading(
                      context: context,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add,
                enabled: _extensionMinutes < 120,
                onTap: _increment,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick preset duration chips
          Row(
            children: [5, 10, 15, 25].map((mins) {
              final isSelected = _extensionMinutes == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _extensionMinutes = mins;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.peachColor(context)
                            : AppTheme.sandColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.inkColor(context),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+${mins}m',
                          style: AppTheme.sansBody(
                            context: context,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Action Button
          TactileButton(
            label: 'Extend session (+${_extensionMinutes}m)',
            fillColor: AppTheme.peachColor(context),
            height: 48,
            borderRadius: 14,
            fontSize: 15,
            onTap: () => widget.onExtend(_extensionMinutes),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.sandColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
            boxShadow: enabled ? AppTheme.smallShadow(context) : null,
          ),
          child: Icon(icon, size: 18, color: AppTheme.text(context)),
        ),
      ),
    );
  }
}
