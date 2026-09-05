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
    if (index == 0 || index == 2 || index == 3) {
      context.read<TimerProvider>().refreshFromStorage();
    }
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: IndexedStack(
        index: _currentTabIndex,
        children: const [
          _TodayView(),
          BattlesScreen(),
          HistoryScreen(),
          ProfileScreen(),
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
                        context: context,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: AppTheme.text(context),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'FOCUS CLUB',
                      style: AppTheme.sansLabel(
                        context: context,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: AppTheme.muted(context),
                      ),
                    ),
                  ],
                ),

                // Spacer to keep centered header balanced
                const SizedBox(width: 38),
              ],
            ),

            const SizedBox(height: 28),

            // Solo Focus Label & Serif Headline
            Text('SOLO FOCUS', style: AppTheme.sansLabel(context: context)),
            const SizedBox(height: 6),
            Text(
              'One thing\nat a time.',
              style: AppTheme.serifHeading(
                context: context,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A quiet $selectedMinutes minutes for the work that matters.',
              style: AppTheme.sansBody(
                context: context,
                fontSize: 14,
                color: AppTheme.muted(context),
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
                      CustomPaint(
                        size: const Size(210, 210),
                        painter: OrganicCirclePainter(
                          color: AppTheme.inkColor(context),
                          strokeWidth: 1.5,
                        ),
                      ),

                      // Tiny decorative sparkle doodles around timer
                      Positioned(
                        top: 14,
                        right: 18,
                        child: SparkleDoodle(size: 16, color: AppTheme.inkColor(context)),
                      ),
                      Positioned(
                        bottom: 22,
                        left: 16,
                        child: SparkleDoodle(size: 12, color: AppTheme.inkColor(context)),
                      ),

                      // Timer value & sublabel
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.selectedTimerFormatted,
                            style: AppTheme.serifTimer(
                              context: context,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'your next session',
                            style: AppTheme.sansBody(
                              context: context,
                              fontSize: 12,
                              color: AppTheme.muted(context),
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
                    context: context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                ),
                Text(
                  provider.todayProgressText,
                  style: AppTheme.sansBody(
                    context: context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkProgressBar(
              progress: provider.todayProgressRatio,
              height: 7,
              fillColor: AppTheme.inkColor(context),
              borderColor: AppTheme.inkColor(context),
            ),

            const SizedBox(height: 20),

            // Primary Button: Full width, peach fill, 1.5px border, 3px hard offset shadow
            TactileButton(
              label: 'Start focus',
              fillColor: AppTheme.peachColor(context),
              textColor: AppTheme.ink,
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
                  color: AppTheme.bg(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
                  boxShadow: AppTheme.shadow(context),
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
                            context: context,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogCtx),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.muted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter focus time in minutes (1 - 180):',
                      style: AppTheme.sansBody(
                        context: context,
                        fontSize: 13,
                        color: AppTheme.muted(context),
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
                              context: context,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.sandColor(context),
                              suffixText: 'min ',
                              suffixStyle: AppTheme.sansBody(
                                context: context,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.muted(context),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppTheme.inkColor(context),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppTheme.inkColor(context),
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
                            fillColor: AppTheme.sandColor(context),
                            textColor: AppTheme.text(context),
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
                            fillColor: AppTheme.peachColor(context),
                            textColor: AppTheme.ink,
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
          color: AppTheme.sandColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.inkColor(context), width: 1.5),
          boxShadow: AppTheme.smallShadow(context),
        ),
        child: Icon(icon, color: AppTheme.text(context), size: 20),
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
    final timerProvider = context.watch<TimerProvider>();
    const items = ['Today', 'Battles', 'Log'];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        border: Border(top: BorderSide(color: AppTheme.faint(context), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ...List.generate(items.length, (index) {
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
                          context: context,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? AppTheme.text(context) : AppTheme.lightColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Active underline/ink indicator
                      Container(
                        width: isSelected ? 18 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.text(context) : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Profile tab button next to Log (Instagram-style PFP with active ring)
            Builder(
              builder: (context) {
                final isSelected = currentIndex == 3;
                return Tooltip(
                  message: 'Profile',
                  child: GestureDetector(
                    onTap: () => onTap(3),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.text(context)
                                : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                        child: UserAvatar(
                          avatarPath: timerProvider.userAvatar,
                          size: 30,
                          borderWidth: 1.5,
                          borderColor: AppTheme.inkColor(context),
                          showShadow: false,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
