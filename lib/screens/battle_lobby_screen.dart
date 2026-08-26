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
    if ((isActive || isCountdown) && !_navigatedToFocus && battleProvider.lobbyCountdown == 1) {
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
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No active battle room'),
              const SizedBox(height: 12),
              TactileButton(
                label: 'Return',
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
      backgroundColor: AppTheme.background,
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
                            border: Border.all(color: AppTheme.ink, width: 1.2),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sand,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.ink, width: 1.2),
                        ),
                        child: Text(
                          '${battle.durationMinutes} MINUTE DUEL',
                          style: AppTheme.sansLabel(fontSize: 10),
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
                      color: AppTheme.sand,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.ink, width: 1.5),
                      boxShadow: AppTheme.tactileShadow,
                    ),
                    child: Column(
                      children: [
                        Text('SHARE ROOM CODE', style: AppTheme.sansLabel(fontSize: 10)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              battle.roomCode,
                              style: AppTheme.serifHeading(
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
                                  const SnackBar(
                                    content: Text('Room code copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: AppTheme.ink,
                                  ),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.background,
                                  border: Border.all(color: AppTheme.ink, width: 1.2),
                                ),
                                child: const Icon(Icons.copy, size: 16, color: AppTheme.ink),
                              ),
                              tooltip: 'Copy Code',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your friend can enter this code in LockIn without signing up.',
                          textAlign: TextAlign.center,
                          style: AppTheme.sansBody(fontSize: 12, color: AppTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Text('PARTICIPANTS (1V1)', style: AppTheme.sansLabel(fontSize: 11)),
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
                          color: AppTheme.inkFaint,
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
                              color: AppTheme.sand,
                              border: Border.all(color: AppTheme.inkFaint, width: 1.0),
                            ),
                            child: const Icon(Icons.hourglass_empty, size: 18, color: AppTheme.inkMuted),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waiting for opponent...',
                                style: AppTheme.sansBody(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.inkMuted,
                                ),
                              ),
                              Text(
                                'Share the code above to connect',
                                style: AppTheme.sansBody(fontSize: 12, color: AppTheme.inkLight),
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
                    fillColor: isLocalReady ? AppTheme.sage : AppTheme.peach,
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
                color: AppTheme.ink.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SparkleDoodle(size: 32, color: AppTheme.sand),
                      const SizedBox(height: 16),
                      Text(
                        'STARTING IN',
                        style: AppTheme.sansLabel(
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
                          color: AppTheme.background,
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
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.ink, width: 1.5),
        ),
        title: Text('Leave Lobby?', style: AppTheme.serifHeading(fontSize: 20)),
        content: Text(
          'Leaving will cancel your battle invitation.',
          style: AppTheme.sansBody(color: AppTheme.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay', style: AppTheme.sansBody(color: AppTheme.ink)),
          ),
          TactileButton(
            label: 'Leave',
            fillColor: const Color(0xFFFBEBE8),
            textColor: AppTheme.errorMuted,
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
              color: isReady ? AppTheme.sage : AppTheme.sand,
              border: Border.all(color: AppTheme.ink, width: 1.2),
            ),
            child: Center(
              child: Text(
                participant!.displayName.isNotEmpty
                    ? participant!.displayName[0].toUpperCase()
                    : '?',
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
                Row(
                  children: [
                    Text(
                      participant!.displayName,
                      style: AppTheme.sansBody(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(You)',
                        style: AppTheme.sansLabel(
                          fontSize: 10,
                          color: AppTheme.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isHost ? 'Host' : 'Challenger',
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
              color: isReady ? AppTheme.sage : AppTheme.sand,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.ink, width: 1),
            ),
            child: Text(
              isReady ? 'READY' : 'NOT READY',
              style: AppTheme.sansLabel(
                fontSize: 10,
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
