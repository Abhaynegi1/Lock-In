import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import 'doodle_decorations.dart';

class CloudSyncModal extends StatelessWidget {
  const CloudSyncModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CloudSyncModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final timerProvider = context.read<TimerProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.ink, width: 1.5),
        boxShadow: AppTheme.tactileShadow,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.inkLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.sand,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.ink, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.cloud_outlined,
                          size: 20,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloud Backup',
                            style: AppTheme.serifHeading(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            auth.isAuthenticated ? 'Account Connected' : 'Local-First Sync',
                            style: AppTheme.sansLabel(
                              fontSize: 10,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 22,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.inkFaint, thickness: 1),
              const SizedBox(height: 16),

              if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEBE8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorMuted, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.errorMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: AppTheme.sansBody(
                            fontSize: 12,
                            color: AppTheme.errorMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!auth.isAuthenticated) ...[
                // Unauthenticated explanation
                Text(
                  'Backup your focus history, streaks, and preferences safely to the cloud.',
                  style: AppTheme.sansBody(
                    fontSize: 14,
                    color: AppTheme.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Benefit points
                const _SyncFeatureTile(
                  icon: Icons.offline_bolt_outlined,
                  title: '100% Local-First',
                  subtitle: 'Lock-In always works offline without signing in.',
                ),
                const SizedBox(height: 10),
                const _SyncFeatureTile(
                  icon: Icons.devices_outlined,
                  title: 'Cross-Device Sync',
                  subtitle: 'Access your logs and targets on any device.',
                ),
                const SizedBox(height: 10),
                const _SyncFeatureTile(
                  icon: Icons.shield_outlined,
                  title: 'Streak & Log Protection',
                  subtitle: 'Never lose your focus momentum if you switch phones.',
                ),
                const SizedBox(height: 24),

                // Sign in with Google button
                TactileButton(
                  label: auth.isSyncing ? 'Connecting...' : 'Continue with Google',
                  fillColor: AppTheme.peach,
                  height: 52,
                  borderRadius: 16,
                  fontSize: 15,
                  onTap: auth.isSyncing
                      ? () {}
                      : () async {
                          final success = await auth.signInWithGoogle(
                            timerProvider: timerProvider,
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connected to Google & Synced!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              ] else ...[
                // Authenticated view
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.sand,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.ink, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Avatar circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.peach,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.ink, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            auth.userDisplayName.isNotEmpty
                                ? auth.userDisplayName[0].toUpperCase()
                                : 'U',
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
                              auth.userDisplayName,
                              style: AppTheme.sansBody(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.userEmail,
                              style: AppTheme.sansBody(
                                fontSize: 12,
                                color: AppTheme.inkMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sage,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.ink, width: 1.0),
                        ),
                        child: Text(
                          'CONNECTED',
                          style: AppTheme.sansLabel(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sync status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last Synced:',
                      style: AppTheme.sansBody(
                        fontSize: 12,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    Text(
                      auth.lastSyncedAt != null
                          ? DateFormat('MMM d, h:mm a').format(auth.lastSyncedAt!)
                          : 'Up to date',
                      style: AppTheme.sansBody(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TactileButton(
                        label: auth.isSyncing ? 'Syncing...' : 'Sync Now',
                        fillColor: AppTheme.peach,
                        height: 48,
                        borderRadius: 14,
                        fontSize: 14,
                        onTap: auth.isSyncing
                            ? () {}
                            : () async {
                                await auth.syncData(timerProvider: timerProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cloud sync complete!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TactileButton(
                        label: 'Sign Out',
                        fillColor: AppTheme.sand,
                        height: 48,
                        borderRadius: 14,
                        fontSize: 14,
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Signed out. Local data preserved.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Signing out keeps all local history and statistics on this device.',
                    style: AppTheme.sansLabel(
                      fontSize: 10,
                      color: AppTheme.inkLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SyncFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ink, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.sansBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.sansBody(
                    fontSize: 11,
                    color: AppTheme.inkMuted,
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
