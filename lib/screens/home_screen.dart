import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import '../widgets/user_avatar.dart';
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

  void _onTabTapped(int index) {
    if (index == 0 || index == 2) {
      context.read<TimerProvider>().refreshFromStorage();
    }
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentTabIndex,
        children: const [
          _TodayView(),
          BattlesScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: _QuietBottomNav(
        currentIndex: _currentTabIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// The Main "Today" Screen
class _TodayView extends StatelessWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: UserAvatar(
                    avatarPath: provider.userAvatar,
                    size: 38,
                    borderWidth: 1.5,
                    showShadow: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Solo Focus Label & Serif Headline
            Text('SOLO FOCUS', style: AppTheme.sansLabel()),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
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
                  // Custom duration option
                  DurationChip(
                    label: ![15, 25, 45, 60].contains(selectedMinutes)
                        ? 'Custom (${selectedMinutes}m)'
                        : 'Custom',
                    isSelected: ![15, 25, 45, 60].contains(selectedMinutes),
                    onTap: () => _showCustomTimeDialog(context, provider),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Main Timer / Intent Area (Organic hand-drawn circle with sparkle doodles)
            Center(
              child: GestureDetector(
                onDoubleTap: () => _showCustomTimeDialog(context, provider),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Organic Hand-Drawn doodle circle outline
                      const CustomPaint(
                        size: Size(210, 210),
                        painter: OrganicCirclePainter(
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
            InkProgressBar(progress: provider.todayProgressRatio, height: 7),

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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCustomTimeDialog(BuildContext context, TimerProvider provider) {
    final controller = TextEditingController(
      text: provider.selectedDurationMinutes.toString(),
    );
    // Select all text so typing immediately replaces
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Custom focus time',
                          style: AppTheme.serifHeading(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogCtx),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter focus time in minutes (1 - 180):',
                      style: AppTheme.sansBody(
                        fontSize: 13,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quick numeric stepper + input field
                    Row(
                      children: [
                        _DialogAdjustBtn(
                          icon: Icons.remove,
                          onTap: () {
                            final current =
                                int.tryParse(controller.text) ??
                                provider.selectedDurationMinutes;
                            final next = (current - 5).clamp(1, 180);
                            controller.text = next.toString();
                            controller.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: controller.text.length,
                            );
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: AppTheme.serifTimer(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.sand,
                              suffixText: 'min ',
                              suffixStyle: AppTheme.sansBody(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.inkMuted,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppTheme.ink,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppTheme.ink,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _DialogAdjustBtn(
                          icon: Icons.add,
                          onTap: () {
                            final current =
                                int.tryParse(controller.text) ??
                                provider.selectedDurationMinutes;
                            final next = (current + 5).clamp(1, 180);
                            controller.text = next.toString();
                            controller.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: controller.text.length,
                            );
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TactileButton(
                            label: 'Cancel',
                            fillColor: AppTheme.sand,
                            height: 48,
                            borderRadius: 14,
                            fontSize: 14,
                            onTap: () => Navigator.pop(dialogCtx),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TactileButton(
                            label: 'Set time',
                            fillColor: AppTheme.peach,
                            height: 48,
                            borderRadius: 14,
                            fontSize: 14,
                            onTap: () {
                              final mins = int.tryParse(controller.text.trim());
                              if (mins != null && mins > 0) {
                                provider.selectDuration(mins.clamp(1, 180));
                              }
                              Navigator.pop(dialogCtx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DialogAdjustBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DialogAdjustBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.sand,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.ink, width: 1.5),
          boxShadow: AppTheme.smallTactileShadow,
        ),
        child: Icon(icon, color: AppTheme.ink, size: 20),
      ),
    );
  }
}

/// Quiet, minimal bottom navigation with simple text & active ink marker
class _QuietBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _QuietBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = ['Today', 'Battles', 'Log'];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.inkFaint, width: 1.0)),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[index],
                      style: AppTheme.sansBody(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
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
