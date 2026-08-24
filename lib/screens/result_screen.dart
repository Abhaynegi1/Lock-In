import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final isWin = provider.status == SessionStatus.won;
    final isBattle = provider.activeSessionType == SessionType.battle;
    final activeBattle = provider.activeBattle;
    final durationMinutes = provider.totalSeconds ~/ 60;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Status Icon / Doodle Badge (tappable to quickly dismiss/return)
              GestureDetector(
                onTap: () {
                  provider.reset();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: isWin
                    ? const LockInLogo(size: 52, hasBorder: true)
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.sand,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.ink, width: 1.5),
                          boxShadow: AppTheme.smallTactileShadow,
                        ),
                        child: const Center(
                          child: Icon(Icons.close, size: 24, color: AppTheme.ink),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Headline & Description
              Text(
                isWin ? 'Session completed.' : 'Session interrupted.',
                style: AppTheme.serifHeading(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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

              const SizedBox(height: 36),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 28),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _ResultStatCard(
                      label: 'DURATION',
                      value: '${durationMinutes}m',
                      subtitle: isWin ? 'Focused' : 'Target was',
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
                            isWin
                                ? '+$durationMinutes minutes added'
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

              const Spacer(),

              // Primary return action
              TactileButton(
                label: 'Back to Today',
                fillColor: isWin ? AppTheme.peach : AppTheme.sand,
                height: 54,
                borderRadius: 16,
                fontSize: 16,
                onTap: () {
                  provider.reset();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              const SizedBox(height: 16),
            ],
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
            style: AppTheme.serifHeading(fontSize: 24, fontWeight: FontWeight.w700),
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
