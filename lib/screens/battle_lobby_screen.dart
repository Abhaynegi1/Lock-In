import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/battle_state.dart';
import '../providers/battle_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'battle_focus_screen.dart';

class BattleLobbyScreen extends StatefulWidget {
  const BattleLobbyScreen({super.key});

  @override
  State<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends State<BattleLobbyScreen> {
  bool _navigatedToFocus = false;

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();
    final battle = battleProvider.currentBattle;
    final isCountdown = battleProvider.status == BattleStatus.countdown;
    final isActive = battleProvider.status == BattleStatus.active;

    // Navigate to focus screen once battle starts or countdown finishes
    if ((isActive || (isCountdown && battleProvider.lobbyCountdown <= 1)) &&
        !_navigatedToFocus) {
      _navigatedToFocus = true;
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BattleFocusScreen()),
        );
      });
    }

    if (battle == null) {
      return Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No active battle room', style: AppTheme.sansBody(context: context)),
              const SizedBox(height: 12),
              TactileButton(
                label: 'Return',
                fillColor: AppTheme.peachColor(context),
                textColor: AppTheme.ink,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    final host = battle.host;
    final guest = battle.guest;
    final isLocalReady = battleProvider.isLocalReady;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _showLeaveDialog(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: AppTheme.text(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sandColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
                        ),
                        child: Text(
                          '${battle.durationMinutes} MINUTE DUEL',
                          style: AppTheme.sansLabel(context: context, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Room Code Hero Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.sandColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
                      boxShadow: AppTheme.shadow(context),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'SHARE ROOM CODE',
                          style: AppTheme.sansLabel(context: context, fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              battle.roomCode,
                              style: AppTheme.serifHeading(
                                context: context,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 6.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: battle.roomCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Room code copied to clipboard!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppTheme.inkColor(context),
                                  ),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.bg(context),
                                  border: Border.all(
                                    color: AppTheme.inkColor(context),
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: AppTheme.text(context),
                                ),
                              ),
                              tooltip: 'Copy Code',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your friend can enter this code in LockIn without signing up.',
                          textAlign: TextAlign.center,
                          style: AppTheme.sansBody(
                            context: context,
                            fontSize: 12,
                            color: AppTheme.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Text(
                    'PARTICIPANTS (1V1)',
                    style: AppTheme.sansLabel(context: context, fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // Host Card
                  _ParticipantCard(
                    participant: host,
                    isHost: true,
                    isMe: host?.id == battleProvider.localParticipantId,
                  ),
                  const SizedBox(height: 12),

                  // Guest Card / Waiting placeholder
                  if (guest != null)
                    _ParticipantCard(
                      participant: guest,
                      isHost: false,
                      isMe: guest.id == battleProvider.localParticipantId,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.faint(context),
                          width: 1.2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.sandColor(context),
                              border: Border.all(
                                color: AppTheme.faint(context),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              Icons.hourglass_empty,
                              size: 18,
                              color: AppTheme.muted(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waiting for opponent...',
                                style: AppTheme.sansBody(
                                  context: context,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.muted(context),
                                ),
                              ),
                              Text(
                                'Share the code above to connect',
                                style: AppTheme.sansBody(
                                  context: context,
                                  fontSize: 12,
                                  color: AppTheme.lightColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Ready Button
                  TactileButton(
                    label: isLocalReady ? 'READY! (WAITING)' : 'MARK AS READY',
                    fillColor: isLocalReady ? AppTheme.sageColor(context) : AppTheme.peachColor(context),
                    textColor: AppTheme.ink,
                    height: 52,
                    fontSize: 15,
                    onTap: () {
                      battleProvider.toggleReady();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Countdown Overlay
            if (isCountdown)
              Container(
                color: (AppTheme.isDark(context) ? Colors.black : AppTheme.ink).withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SparkleDoodle(size: 32, color: AppTheme.peachColor(context)),
                      const SizedBox(height: 16),
                      Text(
                        'STARTING IN',
                        style: AppTheme.sansLabel(
                          context: context,
                          fontSize: 14,
                          color: AppTheme.sand,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${battleProvider.lobbyCountdown}',
                        style: AppTheme.serifHeading(
                          fontSize: 84,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lock in and focus together.',
                        style: AppTheme.sansBody(
                          fontSize: 14,
                          color: AppTheme.sand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.inkColor(context), width: 1.5),
        ),
        title: Text('Leave Lobby?', style: AppTheme.serifHeading(context: context, fontSize: 20)),
        content: Text(
          'Leaving will cancel your battle invitation.',
          style: AppTheme.sansBody(context: context, color: AppTheme.muted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay', style: AppTheme.sansBody(context: context, color: AppTheme.text(context))),
          ),
          TactileButton(
            label: 'Leave',
            fillColor: AppTheme.alertSurfaceColor(context),
            textColor: AppTheme.error(context),
            isFullWidth: false,
            height: 42,
            onTap: () {
              Navigator.pop(ctx);
              context.read<BattleProvider>().resetBattle();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final BattleParticipant? participant;
  final bool isHost;
  final bool isMe;

  const _ParticipantCard({
    required this.participant,
    required this.isHost,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (participant == null) return const SizedBox.shrink();

    final isReady = participant!.isReady;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isReady ? AppTheme.sageColor(context) : AppTheme.sandColor(context),
              border: Border.all(color: AppTheme.inkColor(context), width: 1.2),
            ),
            child: Center(
              child: Text(
                participant!.displayName.isNotEmpty
                    ? participant!.displayName[0].toUpperCase()
                    : '?',
                style: AppTheme.serifHeading(
                  context: context,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isReady ? AppTheme.ink : AppTheme.text(context),
                ),
              ),
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
                      participant!.displayName,
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(You)',
                        style: AppTheme.sansLabel(
                          context: context,
                          fontSize: 10,
                          color: AppTheme.muted(context),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isHost ? 'Host' : 'Challenger',
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 12,
                    color: AppTheme.muted(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isReady ? AppTheme.sageColor(context) : AppTheme.sandColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.inkColor(context), width: 1),
            ),
            child: Text(
              isReady ? 'READY' : 'NOT READY',
              style: AppTheme.sansLabel(
                context: context,
                fontSize: 10,
                color: isReady ? AppTheme.ink : AppTheme.text(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
