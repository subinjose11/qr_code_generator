import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_generator/data/repositories/qr_repository.dart';
import 'package:qr_code_generator/main.dart';

void main() {
  testWidgets('QRLink app launches home screen smoke test', (WidgetTester tester) async {
    final repo = QrRepository();
    await tester.pumpWidget(QrStudioApp(repository: repo, showSplash: false));
    expect(find.textContaining('QRLink'), findsWidgets);
  });

  testWidgets('QRLink splash screen displays and navigates to home', (WidgetTester tester) async {
    final repo = QrRepository();
    await tester.pumpWidget(QrStudioApp(repository: repo, showSplash: true));
    expect(find.textContaining('QRLink'), findsWidgets);
    expect(find.text('Scan  •  Create  •  Connect'), findsOneWidget);

    // Step through the setState timer, fade animation, and duration
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('QRLink Studio'), findsWidgets);
  });
}
