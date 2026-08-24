import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile Card
              Row(
                children: [
                  const LockInLogo(size: 56, hasBorder: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lock In Member',
                          style: AppTheme.serifHeading(fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quiet deep work club',
                          style: AppTheme.sansBody(
                            fontSize: 13,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SparkleDoodle(size: 22, color: AppTheme.ink),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 24),

              // Overview Section
              Text(
                'PERSONAL STATS',
                style: AppTheme.sansLabel(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProfileMetricBox(
                      title: 'Current Streak',
                      value: '${provider.currentStreak} days',
                      subtitle: 'Consecutive focus',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileMetricBox(
                      title: 'Daily Target',
                      value: '${provider.dailyGoalMinutes ~/ 60} hours',
                      subtitle: 'Active daily goal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Focus Philosophy / Manifesto
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.sand,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.ink, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SparkleDoodle(size: 16, color: AppTheme.ink),
                        const SizedBox(width: 8),
                        Text(
                          'The Lock In Rule',
                          style: AppTheme.sansBody(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One thing at a time. When a session begins, leaving the app forfeits your timer. True focus is unbroken presence.',
                      style: AppTheme.sansBody(
                        fontSize: 13,
                        color: AppTheme.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Accountability Rules
              Text(
                'PREFERENCES',
                style: AppTheme.sansLabel(),
              ),
              const SizedBox(height: 12),
              _SettingTile(
                title: 'Strict anti-distraction',
                subtitle: 'Instantly forfeit on app exit',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sage,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.ink, width: 1),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: AppTheme.sansLabel(
                      fontSize: 10,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SettingTile(
                title: 'Tactile sound cues',
                subtitle: 'Subtle chime on session finish',
                trailing: Text(
                  'On',
                  style: AppTheme.sansBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMetricBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _ProfileMetricBox({
    required this.title,
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
            title,
            style: AppTheme.sansLabel(fontSize: 10, color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.serifHeading(fontSize: 20, fontWeight: FontWeight.w700),
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

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.inkFaint, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.sansBody(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.sansBody(
                  fontSize: 12,
                  color: AppTheme.inkMuted,
                ),
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }
}
