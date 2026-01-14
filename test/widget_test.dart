import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_viewer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MarkPressApp smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MarkPressApp());
    
    // Wait for animations and async localizations to settle
    await tester.pumpAndSettle();

    // Verify that the app title is present.
    // It might appear in the AppBar and potentially in the welcome content.
    expect(find.text('MarkPress'), findsWidgets);
    
    // Verify that the initial welcome tab/content is present.
    expect(find.textContaining('Welcome'), findsWidgets);
  });
}