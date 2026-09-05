import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle_model.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../services/screen_wake_service.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'result_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  Timer? _backgroundForfeitTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<TimerProvider>();
        if (provider.isStrictAntiDistraction &&
            provider.status == SessionStatus.running) {
          unawaited(ScreenWakeService.enable());
        }
      }
    });
  }

  @override
  void dispose() {
    _backgroundForfeitTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ScreenWakeService.disable());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<TimerProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (provider.isStrictAntiDistraction &&
          provider.status == SessionStatus.running) {
        // Debounce to allow transient screen rotation / orientation changes
        _backgroundForfeitTimer?.cancel();
        _backgroundForfeitTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            final prov = context.read<TimerProvider>();
            if (prov.isStrictAntiDistraction &&
                prov.status == SessionStatus.running) {
              prov.forfeitSession();
            }
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // App resumed - cancel pending forfeit timer and sync elapsed timer
      _backgroundForfeitTimer?.cancel();
      _backgroundForfeitTimer = null;
      if (provider.isStrictAntiDistraction &&
          provider.status == SessionStatus.running) {
        unawaited(ScreenWakeService.enable());
      }
      provider.syncTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final isBattle = provider.activeSessionType == SessionType.battle;
    final activeBattle = provider.activeBattle;

    // Listen for completion and navigate to result
    if (provider.status == SessionStatus.won ||
        provider.status == SessionStatus.lost) {
      unawaited(ScreenWakeService.disable());
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      });
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(context, provider, isBattle, activeBattle)
            : _buildPortraitLayout(context, provider, isBattle, activeBattle),
      ),
    );
  }

  Widget _buildHeader(
    TimerProvider provider,
    bool isBattle,
    BattleModel? activeBattle,
  ) {
    if (isBattle && activeBattle != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.sand,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.ink, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SparkleDoodle(size: 14),
                const SizedBox(width: 8),
                Text(
                  'Battle with ${activeBattle.opponentName}',
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const LockInLogo(size: 24, hasBorder: true),
            const SizedBox(width: 8),
            Text(
              provider.isExtending
                  ? 'EXTENDING FOCUS · ${provider.baseCompletedMinutes}M SAVED'
                  : 'SOLO FOCUS',
              style: AppTheme.sansLabel(fontSize: 10),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: provider.isStrictAntiDistraction
                ? AppTheme.sand
                : AppTheme.sage,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.inkFaint, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                provider.isStrictAntiDistraction
                    ? 'STRICT · SCREEN AWAKE'
                    : 'FLEXIBLE FOCUS',
                style: AppTheme.sansLabel(fontSize: 9, color: AppTheme.ink),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    TimerProvider provider,
    bool isBattle,
    BattleModel? activeBattle,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    _buildHeader(provider, isBattle, activeBattle),
                    const Spacer(flex: 2),

                    // Main Organic Doodle Timer Circle
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
                              child: SparkleDoodle(
                                size: 18,
                                color: AppTheme.ink,
                              ),
                            ),
                            const Positioned(
                              bottom: 24,
                              left: 20,
                              child: SparkleDoodle(
                                size: 14,
                                color: AppTheme.ink,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  provider.timerString,
                                  style: AppTheme.serifTimer(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.isExtending
                                      ? 'extension · ${provider.baseCompletedMinutes}m locked in'
                                      : (isBattle
                                          ? 'focusing together'
                                          : 'remaining focus'),
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

                    const SizedBox(height: 24),

                    // Minimalist linear progress indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: InkProgressBar(
                        progress: provider.completionRatio,
                        height: 6,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Supportive calm prompt
                    Text(
                      provider.isExtending
                          ? "Pushing boundaries. Keep momentum rolling."
                          : _getCalmSubtext(provider.progress, isBattle),
                      textAlign: TextAlign.center,
                      style: AppTheme.serifHeading(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.inkMuted,
                      ),
                    ),

                    const Spacer(),

                    // End Session Action: Tactile secondary button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TactileButton(
                        label: provider.isExtending
                            ? 'End extension early'
                            : 'End session early',
                        leading: const Icon(
                          Icons.stop_circle_outlined,
                          size: 18,
                          color: AppTheme.ink,
                        ),
                        fillColor: AppTheme.sand,
                        textColor: AppTheme.ink,
                        borderColor: AppTheme.ink,
                        height: 48,
                        borderRadius: 14,
                        fontSize: 14,
                        onTap: () => _showGiveUpDialog(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    TimerProvider provider,
    bool isBattle,
    BattleModel? activeBattle,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Column: Timer Circle
            Expanded(
              flex: 5,
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CustomPaint(
                        size: Size(190, 190),
                        painter: OrganicCirclePainter(
                          color: AppTheme.ink,
                          strokeWidth: 1.6,
                        ),
                      ),
                      const Positioned(
                        top: 14,
                        right: 16,
                        child: SparkleDoodle(size: 16, color: AppTheme.ink),
                      ),
                      const Positioned(
                        bottom: 18,
                        left: 14,
                        child: SparkleDoodle(size: 12, color: AppTheme.ink),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.timerString,
                            style: AppTheme.serifTimer(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.isExtending
                                ? 'extension · ${provider.baseCompletedMinutes}m locked in'
                                : (isBattle
                                    ? 'focusing together'
                                    : 'remaining focus'),
                            style: AppTheme.sansBody(
                              fontSize: 11,
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
            ),
            const SizedBox(width: 24),

            // Right Column: Controls, Progress, and Header
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(provider, isBattle, activeBattle),
                  const SizedBox(height: 12),
                  Text(
                    provider.isExtending
                        ? "Pushing boundaries. Keep momentum rolling."
                        : _getCalmSubtext(provider.progress, isBattle),
                    style: AppTheme.serifHeading(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkProgressBar(progress: provider.completionRatio, height: 6),
                  const SizedBox(height: 16),
                  TactileButton(
                    label: provider.isExtending
                        ? 'End extension early'
                        : 'End session early',
                    leading: const Icon(
                      Icons.stop_circle_outlined,
                      size: 18,
                      color: AppTheme.ink,
                    ),
                    fillColor: AppTheme.sand,
                    textColor: AppTheme.ink,
                    borderColor: AppTheme.ink,
                    height: 44,
                    borderRadius: 14,
                    fontSize: 13,
                    onTap: () => _showGiveUpDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCalmSubtext(double remainingProgress, bool isBattle) {
    if (isBattle) {
      if (remainingProgress > 0.6) return "Holding each other accountable.";
      if (remainingProgress > 0.2) {
        return "Every deep minute counts toward your score.";
      }
      return "Finish unbroken.";
    }
    if (remainingProgress > 0.6) return "Deep, undivided presence.";
    if (remainingProgress > 0.2) return "Stay with the task at hand.";
    return "Finishing strong.";
  }

  void _showGiveUpDialog(BuildContext context) {
    final prov = context.read<TimerProvider>();
    final isExtending = prov.isExtending;
    final baseMinutes = prov.baseCompletedMinutes;

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
                isExtending ? 'End extension?' : 'End focus session?',
                style: AppTheme.serifHeading(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isExtending
                    ? 'Leaving now will end the extension early. Your completed ${baseMinutes}m session is already safely saved!'
                    : 'Leaving now will mark this session as incomplete and reset your current streak.',
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
                      label: isExtending ? 'Keep extending' : 'Stay locked in',
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
                      label: isExtending ? 'End extension' : 'End session',
                      fillColor: const Color(0xFFFBEBE8),
                      textColor: AppTheme.errorMuted,
                      height: 46,
                      borderRadius: 14,
                      fontSize: 13,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<TimerProvider>().forfeitSession();
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
