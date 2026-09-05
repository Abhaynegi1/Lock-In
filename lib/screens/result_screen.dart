import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'focus_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final isWin = provider.status == SessionStatus.won;
    final isBattle = provider.activeSessionType == SessionType.battle;
    final activeBattle = provider.activeBattle;
    final targetMinutes = provider.totalSeconds ~/ 60;
    final lastSession = provider.history.isNotEmpty
        ? provider.history.first
        : null;
    final actualMinutes = isWin
        ? targetMinutes
        : (lastSession?.durationMinutes ??
              ((provider.totalSeconds - provider.secondsRemaining) / 60)
                  .round());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Icon / Doodle Badge (tappable to quickly dismiss/return)
                      GestureDetector(
                        onTap: () {
                          provider.reset();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: isWin
                            ? const LockInLogo(size: 48, hasBorder: true)
                            : Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.sand,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.ink,
                                    width: 1.5,
                                  ),
                                  boxShadow: AppTheme.smallTactileShadow,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close,
                                    size: 22,
                                    color: AppTheme.ink,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Headline & Description
                      Text(
                        isWin ? 'Session completed.' : 'Session interrupted.',
                        style: AppTheme.serifHeading(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isWin
                            ? (isBattle
                                  ? 'Great accountability work. Your minutes have been added to the battle.'
                                  : 'Unbroken deep work recorded. Your momentum continues.')
                            : 'The session ended early. Rest for a minute and start fresh when ready.',
                        style: AppTheme.sansBody(
                          fontSize: 14,
                          color: AppTheme.inkMuted,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Reassurance banner if extension was interrupted
                      if (provider.extensionInterrupted) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.sand,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.ink, width: 1.2),
                            boxShadow: AppTheme.smallTactileShadow,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: AppTheme.ink,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Extension ended early. Your ${actualMinutes}m session was safely recorded!',
                                  style: AppTheme.sansBody(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Divider(color: AppTheme.inkFaint, thickness: 1),
                      const SizedBox(height: 20),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _ResultStatCard(
                              label: 'DURATION',
                              value: '${actualMinutes}m',
                              subtitle: isWin
                                  ? 'Focused'
                                  : 'Target was ${targetMinutes}m',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ResultStatCard(
                              label: 'CURRENT STREAK',
                              value: '${provider.currentStreak}',
                              subtitle: 'Consecutive days',
                            ),
                          ),
                        ],
                      ),

                      if (isBattle && activeBattle != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.sand,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.ink, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BATTLE WITH ${activeBattle.opponentName.toUpperCase()}',
                                    style: AppTheme.sansLabel(fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    actualMinutes > 0
                                        ? '+$actualMinutes minutes added'
                                        : 'No minutes recorded',
                                    style: AppTheme.sansBody(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                activeBattle.scoreComparison,
                                style: AppTheme.serifHeading(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Extend Session Card (only when session completed successfully)
                      if (isWin) ...[
                        const SizedBox(height: 20),
                        _ExtendSessionCard(
                          onExtend: (minutes) {
                            provider.extendSession(minutes);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FocusScreen(),
                              ),
                            );
                          },
                        ),
                      ],

                      const Spacer(),
                      const SizedBox(height: 20),

                      // Return action
                      TactileButton(
                        label: 'Back to Today',
                        fillColor: AppTheme.sand,
                        height: 50,
                        borderRadius: 16,
                        fontSize: 15,
                        onTap: () {
                          provider.reset();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.ink, width: 1.5),
        boxShadow: AppTheme.tactileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SparkleDoodle(size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'EXTEND SESSION',
                    style: AppTheme.sansLabel(
                      fontSize: 11,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
              Text(
                'Keep momentum rolling',
                style: AppTheme.sansBody(
                  fontSize: 11,
                  color: AppTheme.inkMuted,
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
                        color: isSelected ? AppTheme.peach : AppTheme.sand,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.ink,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+${mins}m',
                          style: AppTheme.sansBody(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppTheme.ink,
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
            fillColor: AppTheme.peach,
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
            color: AppTheme.sand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.ink, width: 1.2),
            boxShadow: enabled ? AppTheme.smallTactileShadow : null,
          ),
          child: Center(
            child: Icon(icon, size: 20, color: AppTheme.ink),
          ),
        ),
      ),
    );
  }
}


class _ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _ResultStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ink, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.sansLabel(fontSize: 10, color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.serifHeading(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.sansBody(fontSize: 11, color: AppTheme.inkLight),
          ),
        ],
      ),
    );
  }
}
