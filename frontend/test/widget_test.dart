import 'package:flutter_test/flutter_test.dart';
import 'package:visimed/main.dart';

void main() {
  testWidgets('VisiMed login screen renders', (tester) async {
    await tester.pumpWidget(const VisiMedApp());
    expect(find.text('VisiMed'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
