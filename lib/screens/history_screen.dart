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
    final totalMinutes = history
        .where((s) => s.isWin)
        .fold(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    // Group history sessions by calendar date
    final Map<DateTime, List<FocusSession>> groupedHistory = {};
    for (final session in history) {
      final dateKey = DateTime(
        session.dateTime.year,
        session.dateTime.month,
        session.dateTime.day,
      );
      groupedHistory.putIfAbsent(dateKey, () => []).add(session);
    }

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
                      Text('FOCUS LOG', style: AppTheme.sansLabel()),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
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
                    Container(width: 1, height: 36, color: AppTheme.inkFaint),
                    _StatColumn(value: '$wonSessions', label: 'Completed'),
                    Container(width: 1, height: 36, color: AppTheme.inkFaint),
                    _StatColumn(
                      value: '${provider.currentStreak}',
                      label: 'Streak',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 10),

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
                for (final entry in groupedHistory.entries) ...[
                  _DateSeparator(date: entry.key, sessions: entry.value),
                  ...entry.value.map((session) => _LogItem(session: session)),
                ],
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
          style: AppTheme.sansLabel(fontSize: 10, color: AppTheme.inkMuted),
        ),
      ],
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final List<FocusSession> sessions;

  const _DateSeparator({required this.date, required this.sessions});

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'TODAY · ${DateFormat('MMM d').format(date).toUpperCase()}';
    } else if (date == yesterday) {
      return 'YESTERDAY · ${DateFormat('MMM d').format(date).toUpperCase()}';
    } else if (date.year == now.year) {
      return DateFormat('EEE, MMM d').format(date).toUpperCase();
    } else {
      return DateFormat('MMM d, yyyy').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMins = sessions
        .where((s) => s.isWin)
        .fold(0, (sum, s) => sum + s.durationMinutes);

    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.sand,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.ink, width: 1.0),
            ),
            child: Text(
              _formatDateHeader(date),
              style: AppTheme.sansLabel(
                fontSize: 10,
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppTheme.inkFaint)),
          const SizedBox(width: 10),
          Text(
            totalMins > 0
                ? '$totalMins min'
                : '${sessions.length} session${sessions.length == 1 ? "" : "s"}',
            style: AppTheme.sansLabel(
              fontSize: 10,
              color: AppTheme.inkMuted,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final FocusSession session;

  const _LogItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(session.dateTime);
    final isBattle = session.sessionType == SessionType.battle;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                  !session.isWin &&
                          session.targetDurationMinutes != null &&
                          session.targetDurationMinutes! >
                              session.durationMinutes
                      ? '$timeStr · Target was ${session.targetDurationMinutes}m'
                      : timeStr,
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
