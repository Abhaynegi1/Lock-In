import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'battles_screen.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _TodayView(onNavigateToTab: (index) => setState(() => _currentTabIndex = index)),
          const BattlesScreen(),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _QuietBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
      ),
    );
  }
}

/// The Main "Today" Screen
class _TodayView extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;

  const _TodayView({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final featuredBattle = provider.featuredBattle;
    final selectedMinutes = provider.selectedDurationMinutes;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Logo Icon
                const LockInLogo(size: 38, hasBorder: true),

                // Centered "LOCK IN" / "FOCUS CLUB"
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LOCK IN',
                      style: AppTheme.sansBody(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'FOCUS CLUB',
                      style: AppTheme.sansLabel(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                  ],
                ),

                // Right Profile Icon
                GestureDetector(
                  onTap: () => onNavigateToTab(3), // Navigate to Me
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.sand,
                      border: Border.all(color: AppTheme.ink, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_outline, size: 18, color: AppTheme.ink),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Solo Focus Label & Serif Headline
            Text(
              'SOLO FOCUS',
              style: AppTheme.sansLabel(),
            ),
            const SizedBox(height: 6),
            Text(
              'One thing\nat a time.',
              style: AppTheme.serifHeading(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A quiet $selectedMinutes minutes for the work that matters.',
              style: AppTheme.sansBody(
                fontSize: 14,
                color: AppTheme.inkMuted,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Duration selector chips
            Row(
              children: [
                for (final mins in [15, 25, 45, 60])
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: DurationChip(
                      minutes: mins,
                      isSelected: selectedMinutes == mins,
                      onTap: () => provider.selectDuration(mins),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 28),

            // Main Timer / Intent Area (Organic hand-drawn circle with sparkle doodles)
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Organic Hand-Drawn doodle circle outline
                    CustomPaint(
                      size: const Size(210, 210),
                      painter: const OrganicCirclePainter(
                        color: AppTheme.ink,
                        strokeWidth: 1.5,
                      ),
                    ),

                    // Tiny decorative sparkle doodles around timer
                    const Positioned(
                      top: 14,
                      right: 18,
                      child: SparkleDoodle(size: 16, color: AppTheme.ink),
                    ),
                    const Positioned(
                      bottom: 22,
                      left: 16,
                      child: SparkleDoodle(size: 12, color: AppTheme.ink),
                    ),

                    // Timer value & sublabel
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.selectedTimerFormatted,
                          style: AppTheme.serifTimer(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'your next session',
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

            // Daily Progress Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today',
                  style: AppTheme.sansBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  provider.todayProgressText,
                  style: AppTheme.sansBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkProgressBar(
              progress: provider.todayProgressRatio,
              height: 7,
            ),

            const SizedBox(height: 20),

            // Primary Button: Full width, peach fill, 1.5px black border, 3px hard offset shadow
            TactileButton(
              label: 'Start focus',
              fillColor: AppTheme.peach,
              height: 54,
              borderRadius: 16,
              fontSize: 16,
              onTap: () {
                provider.startSession(
                  minutes: selectedMinutes,
                  type: SessionType.solo,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FocusScreen()),
                );
              },
            ),

            const SizedBox(height: 26),

            // Thin divider before Current Battle
            const Divider(color: AppTheme.inkFaint, thickness: 1),

            const SizedBox(height: 18),

            // Current Battle row (compact, calm, discoverable beneath thin divider)
            if (featuredBattle != null)
              InkWell(
                onTap: () => onNavigateToTab(1), // Switch to Battles tab
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Battle with ${featuredBattle.opponentName}',
                            style: AppTheme.sansBody(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            featuredBattle.isUserAhead
                                ? "You're ahead · ${featuredBattle.endsIn}"
                                : "Behind by ${(featuredBattle.opponentMinutes - featuredBattle.userMinutes)}m · ${featuredBattle.endsIn}",
                            style: AppTheme.sansBody(
                              fontSize: 12,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      featuredBattle.scoreComparison,
                      style: AppTheme.serifHeading(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: () => onNavigateToTab(1),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus Battles',
                            style: AppTheme.sansBody(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Challenge a friend for quiet accountability',
                            style: AppTheme.sansBody(
                              fontSize: 12,
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.sand,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.ink, width: 1.2),
                      ),
                      child: Text(
                        'Start',
                        style: AppTheme.sansLabel(
                          fontSize: 11,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Quiet, minimal bottom navigation with simple text & active ink marker
class _QuietBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _QuietBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = ['Today', 'Battles', 'Log', 'Me'];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.inkFaint, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[index],
                      style: AppTheme.sansBody(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.ink : AppTheme.inkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Active underline/ink indicator
                    Container(
                      width: isSelected ? 18 : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
