import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lock_in/main.dart';
import 'package:lock_in/providers/timer_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TimerProvider(),
        child: const LockInApp(),
      ),
    );

    expect(find.text('LOCK IN'), findsOneWidget);
  });
}
