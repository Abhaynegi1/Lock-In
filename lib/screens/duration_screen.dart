import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/focus_session.dart';
import '../providers/timer_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/doodle_decorations.dart';
import 'focus_screen.dart';

class DurationScreen extends StatefulWidget {
  const DurationScreen({super.key});

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  int _selectedDuration = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text(
          'SELECT DURATION',
          style: AppTheme.sansLabel(context: context, fontSize: 12, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Choose your focus block.',
              style: AppTheme.serifHeading(context: context, fontSize: 26),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick an unbroken duration for this session.',
              style: AppTheme.sansBody(context: context, color: AppTheme.muted(context)),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DurationCard(
                    15,
                    _selectedDuration == 15,
                    () => setState(() => _selectedDuration = 15),
                  ),
                  _DurationCard(
                    25,
                    _selectedDuration == 25,
                    () => setState(() => _selectedDuration = 25),
                  ),
                  _DurationCard(
                    45,
                    _selectedDuration == 45,
                    () => setState(() => _selectedDuration = 45),
                  ),
                  _DurationCard(
                    60,
                    _selectedDuration == 60,
                    () => setState(() => _selectedDuration = 60),
                  ),
                ],
              ),
            ),
            TactileButton(
              label: 'Start focus',
              fillColor: AppTheme.peachColor(context),
              textColor: AppTheme.ink,
              onTap: () {
                context.read<TimerProvider>().startSession(
                  minutes: _selectedDuration,
                  type: SessionType.solo,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FocusScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationCard(this.minutes, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sandColor(context) : AppTheme.bg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.inkColor(context) : AppTheme.faint(context),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected ? AppTheme.smallShadow(context) : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes',
              style: AppTheme.serifHeading(
                context: context,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.text(context) : AppTheme.muted(context),
              ),
            ),
            Text(
              'MINUTES',
              style: AppTheme.sansLabel(
                context: context,
                fontSize: 10,
                color: isSelected ? AppTheme.text(context) : AppTheme.lightColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
