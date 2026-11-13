import 'package:flutter_test/flutter_test.dart';
import 'package:stevethegreat/main.dart';

void main() {
  testWidgets('EmberlightApp boots with HUD overlay', (tester) async {
    await tester.pumpWidget(const EmberlightApp());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.text('ELDVIK CAMP (SAFE)'), findsOneWidget);
  });
}
