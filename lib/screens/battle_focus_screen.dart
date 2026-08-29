import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_state.dart';
import '../providers/battle_provider.dart';
import '../providers/timer_provider.dart';
import '../services/screen_wake_service.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'battle_result_screen.dart';

class BattleFocusScreen extends StatefulWidget {
  const BattleFocusScreen({super.key});

  @override
  State<BattleFocusScreen> createState() => _BattleFocusScreenState();
}

class _BattleFocusScreenState extends State<BattleFocusScreen>
    with WidgetsBindingObserver {
  Timer? _lifecycleForfeitDebounceTimer;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final timerProvider = context.read<TimerProvider>();
        final battleProvider = context.read<BattleProvider>();
        if (timerProvider.isStrictAntiDistraction &&
            battleProvider.status == BattleStatus.active) {
          unawaited(ScreenWakeService.enable());
        }
      }
    });
  }

  @override
  void dispose() {
    _lifecycleForfeitDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ScreenWakeService.disable());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final timerProvider = context.read<TimerProvider>();
    final battleProvider = context.read<BattleProvider>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (timerProvider.isStrictAntiDistraction &&
          battleProvider.status == BattleStatus.active) {
        // Debounce 1.5 seconds for transient screen lock / orientation flip
        _lifecycleForfeitDebounceTimer?.cancel();
        _lifecycleForfeitDebounceTimer = Timer(
          const Duration(milliseconds: 1500),
          () {
            if (mounted) {
              final bProv = context.read<BattleProvider>();
              if (bProv.status == BattleStatus.active) {
                bProv.forfeitBattle(reason: 'Left application during battle');
              }
            }
          },
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      _lifecycleForfeitDebounceTimer?.cancel();
      _lifecycleForfeitDebounceTimer = null;
      if (timerProvider.isStrictAntiDistraction &&
          battleProvider.status == BattleStatus.active) {
        unawaited(ScreenWakeService.enable());
      }
      battleProvider.syncAuthoritativeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final opponent = battleProvider.opponentParticipant;
    final isOpponentDisconnected =
        battleProvider.status == BattleStatus.playerDisconnected;

    // Navigate to result screen when completed
    if (battleProvider.status == BattleStatus.completed &&
        !_navigatedToResult) {
      _navigatedToResult = true;
      unawaited(ScreenWakeService.disable());
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BattleResultScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Header
              _buildHeader(
                battleProvider,
                timerProvider,
                opponent,
                isOpponentDisconnected,
              ),
              const SizedBox(height: 32),

              // Disconnect Grace Notice Banner
              if (isOpponentDisconnected) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEBE8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.errorMuted, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 20,
                        color: AppTheme.errorMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${opponent?.displayName ?? "Opponent"} disconnected',
                              style: AppTheme.sansBody(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorMuted,
                              ),
                            ),
                            Text(
                              'Reconnecting in ${battleProvider.gracePeriodSecondsRemaining}s before forfeit',
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
                ),
                const SizedBox(height: 24),
              ],

              // Central Organic Circle Timer
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CustomPaint(
                        size: Size(240, 240),
                        painter: OrganicCirclePainter(
                          color: AppTheme.ink,
                          strokeWidth: 1.8,
                        ),
                      ),
                      const Positioned(
                        top: 18,
                        right: 22,
                        child: SparkleDoodle(size: 18, color: AppTheme.ink),
                      ),
                      const Positioned(
                        bottom: 24,
                        left: 20,
                        child: SparkleDoodle(size: 14, color: AppTheme.ink),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            battleProvider.timerString,
                            style: AppTheme.serifTimer(
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'focusing with ${opponent?.displayName ?? "Opponent"}',
                            style: AppTheme.sansBody(
                              fontSize: 12,
                              color: AppTheme.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Linear Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: InkProgressBar(
                  progress: battleProvider.completionRatio,
                  height: 6,
                ),
              ),

              const SizedBox(height: 36),

              // Calm accountability prompt
              Text(
                'Hold each other accountable.\nUnbroken focus wins the duel.',
                textAlign: TextAlign.center,
                style: AppTheme.serifHeading(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.inkMuted,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 48),

              // Forfeit / End Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TactileButton(
                  label: 'Forfeit battle early',
                  leading: const Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: AppTheme.ink,
                  ),
                  fillColor: AppTheme.sand,
                  textColor: AppTheme.ink,
                  borderColor: AppTheme.ink,
                  height: 48,
                  borderRadius: 14,
                  fontSize: 14,
                  onTap: () => _showForfeitConfirmDialog(context),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BattleProvider battleProvider,
    TimerProvider timerProvider,
    BattleParticipant? opponent,
    bool isOpponentDisconnected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.sand,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ink, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOpponentDisconnected
                      ? const Color(0xFFFBEBE8)
                      : AppTheme.sage,
                  border: Border.all(color: AppTheme.ink, width: 1),
                ),
                child: Center(
                  child: Text(
                    opponent?.displayName.isNotEmpty == true
                        ? opponent!.displayName[0].toUpperCase()
                        : 'O',
                    style: AppTheme.sansBody(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Duel with ${opponent?.displayName ?? "Opponent"}',
                style: AppTheme.sansBody(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOpponentDisconnected
                  ? const Color(0xFFFBEBE8)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.inkFaint, width: 1),
            ),
            child: Text(
              isOpponentDisconnected ? 'OFFLINE' : 'LIVE 1V1',
              style: AppTheme.sansLabel(
                fontSize: 9,
                color: isOpponentDisconnected
                    ? AppTheme.errorMuted
                    : AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForfeitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.ink, width: 1.5),
            boxShadow: AppTheme.tactileShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forfeit battle?',
                style: AppTheme.serifHeading(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Forfeiting will immediately concede the match to your opponent and end the focus session.',
                style: AppTheme.sansBody(
                  fontSize: 14,
                  color: AppTheme.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TactileButton(
                      label: 'Stay focused',
                      fillColor: AppTheme.sage,
                      height: 46,
                      borderRadius: 14,
                      fontSize: 13,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TactileButton(
                      label: 'Concede',
                      fillColor: const Color(0xFFFBEBE8),
                      textColor: AppTheme.errorMuted,
                      height: 46,
                      borderRadius: 14,
                      fontSize: 13,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<BattleProvider>().forfeitBattle(
                          reason: 'Player conceded early',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
