import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/battle_provider.dart';
import '../providers/timer_provider.dart';
import '../screens/battle_lobby_screen.dart';
import '../utils/app_theme.dart';
import 'doodle_decorations.dart';

class CreateBattleModal extends StatefulWidget {
  const CreateBattleModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBattleModal(),
    );
  }

  @override
  State<CreateBattleModal> createState() => _CreateBattleModalState();
}

class _CreateBattleModalState extends State<CreateBattleModal> {
  late TextEditingController _nameController;
  int _selectedDuration = 25;
  final List<int> _durations = [15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    final timerProvider = context.read<TimerProvider>();
    _nameController = TextEditingController(text: timerProvider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final battleProvider = context.read<BattleProvider>();
    final timerProvider = context.read<TimerProvider>();

    // Update username preference if changed
    if (name != timerProvider.userName) {
      await timerProvider.updateUserName(name);
    }

    final success = await battleProvider.createBattle(
      durationMinutes: _selectedDuration,
      displayName: name,
      avatar: timerProvider.userAvatar,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context); // close modal
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BattleLobbyScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              battleProvider.errorMessage ?? 'Failed to create battle room',
              style: AppTheme.sansBody(color: AppTheme.background),
            ),
            backgroundColor: AppTheme.ink,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final battleProvider = context.watch<BattleProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.ink, width: 1.5),
            left: BorderSide(color: AppTheme.ink, width: 1.5),
            right: BorderSide(color: AppTheme.ink, width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                const SparkleDoodle(size: 20, color: AppTheme.ink),
                const SizedBox(width: 8),
                Text(
                  'Create Focus Battle',
                  style: AppTheme.serifHeading(fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Generate a room code and invite a friend. No account required.',
              style: AppTheme.sansBody(fontSize: 13, color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 20),

            // Display Name
            Text('YOUR DISPLAY NAME', style: AppTheme.sansLabel(fontSize: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: AppTheme.sansBody(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. Maya, Sam, Liam',
                hintStyle: AppTheme.sansBody(color: AppTheme.inkLight),
                filled: true,
                fillColor: AppTheme.sand,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.ink, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.ink, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Battle Duration
            Text('BATTLE DURATION', style: AppTheme.sansLabel(fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: _durations.map((mins) {
                final isSelected = _selectedDuration == mins;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDuration = mins),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.ink : AppTheme.sand,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.ink,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? AppTheme.smallTactileShadow
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${mins}m',
                            style: AppTheme.sansBody(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.background
                                  : AppTheme.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Create Room Action
            TactileButton(
              label: battleProvider.isLoading
                  ? 'Creating Room...'
                  : 'Create Room Code',
              fillColor: AppTheme.peach,
              height: 52,
              fontSize: 15,
              onTap: battleProvider.isLoading ? () {} : _handleCreate,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
