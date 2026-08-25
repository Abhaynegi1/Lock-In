import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final history = provider.history;

    final wonSessions = history.where((s) => s.isWin).length;
    final totalMinutes = history.fold(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOCUS LOG',
                        style: AppTheme.sansLabel(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quiet momentum.',
                        style: AppTheme.serifHeading(fontSize: 26),
                      ),
                    ],
                  ),
                  const LockInLogo(size: 32, hasBorder: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Every completed block of intentional time recorded without distraction.',
                style: AppTheme.sansBody(
                  fontSize: 14,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Stats Row (clean linework box)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.sand,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.ink, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      value: '${totalHours}h',
                      label: 'Total Focused',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.inkFaint,
                    ),
                    _StatColumn(
                      value: '$wonSessions',
                      label: 'Completed',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.inkFaint,
                    ),
                    _StatColumn(
                      value: '${provider.currentStreak}',
                      label: 'Streak',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 20),

              if (history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        const LockInLogo(size: 44, hasBorder: true),
                        const SizedBox(height: 16),
                        Text(
                          'Your log is clean.',
                          style: AppTheme.serifHeading(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete your first focus session to start your momentum.',
                          style: AppTheme.sansBody(color: AppTheme.inkMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...history.map((session) => _LogItem(session: session)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.serifHeading(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.sansLabel(
            fontSize: 10,
            color: AppTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _LogItem extends StatelessWidget {
  final FocusSession session;

  const _LogItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd · HH:mm').format(session.dateTime);
    final isBattle = session.sessionType == SessionType.battle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: session.isWin ? AppTheme.ink : AppTheme.inkFaint,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Indicator dot / symbol
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: session.isWin ? AppTheme.sage : AppTheme.errorMuted,
              border: Border.all(color: AppTheme.ink, width: 1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${session.durationMinutes}m focus',
                      style: AppTheme.sansBody(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isBattle ? AppTheme.peach : AppTheme.sand,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.ink, width: 0.8),
                      ),
                      child: Text(
                        isBattle
                            ? (session.opponentName != null
                                ? 'VS ${session.opponentName!.toUpperCase()}'
                                : 'BATTLE')
                            : 'SOLO',
                        style: AppTheme.sansLabel(
                          fontSize: 9,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  !session.isWin && session.targetDurationMinutes != null && session.targetDurationMinutes! > session.durationMinutes
                      ? '$dateStr · Target was ${session.targetDurationMinutes}m'
                      : dateStr,
                  style: AppTheme.sansBody(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            session.isWin ? 'Completed' : 'Interrupted',
            style: AppTheme.sansBody(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: session.isWin ? AppTheme.ink : AppTheme.errorMuted,
            ),
          ),
        ],
      ),
    );
  }
}
