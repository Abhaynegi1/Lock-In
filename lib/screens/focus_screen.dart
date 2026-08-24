import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'result_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // User left the app - Fail the session under strict anti-distraction rule
      final provider = context.read<TimerProvider>();
      if (provider.status == SessionStatus.running) {
        provider.forfeitSession();
      }
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
      Future.microtask(() {
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Status Bar: Minimal battle strip or solo quiet indicator
              if (isBattle && activeBattle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          const SparkleDoodle(size: 14, color: AppTheme.ink),
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
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const LockInLogo(size: 26, hasBorder: true),
                        const SizedBox(width: 10),
                        Text(
                          'SOLO FOCUS',
                          style: AppTheme.sansLabel(),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sand,
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
                            'STAY IN APP',
                            style: AppTheme.sansLabel(
                              fontSize: 9,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(flex: 2),

              // Main Organic Doodle Timer Circle
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Organic Hand-Drawn Doodle Circle
                      CustomPaint(
                        size: const Size(240, 240),
                        painter: const OrganicCirclePainter(
                          color: AppTheme.ink,
                          strokeWidth: 1.8,
                        ),
                      ),

                      // Decorative Sparkle Doodles
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

                      // Large Serif Digits
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
                            isBattle
                                ? 'focusing together'
                                : 'remaining focus',
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
                _getCalmSubtext(provider.progress, isBattle),
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
                  label: 'End session early',
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
    );
  }

  String _getCalmSubtext(double remainingProgress, bool isBattle) {
    if (isBattle) {
      if (remainingProgress > 0.6) return "Holding each other accountable.";
      if (remainingProgress > 0.2) return "Every deep minute counts toward your score.";
      return "Finish unbroken.";
    }
    if (remainingProgress > 0.6) return "Deep, undivided presence.";
    if (remainingProgress > 0.2) return "Stay with the task at hand.";
    return "Finishing strong.";
  }

  void _showGiveUpDialog(BuildContext context) {
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
                'End focus session?',
                style: AppTheme.serifHeading(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Leaving now will mark this session as incomplete and reset your current streak.',
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
                      label: 'Stay locked in',
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
                      label: 'End session',
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
