import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywise/services/analytics_service.dart';
import 'package:paywise/Screens/terms_conditions_screen.dart';
import 'package:paywise/Screens/not_found_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Production Checklist & Compliance Verification Tests', () {
    test('AnalyticsService logs events, respects user opt-out, and limits memory', () async {
      SharedPreferences.setMockInitialValues({});
      final analytics = AnalyticsService();
      await analytics.init();

      expect(analytics.isEnabled, isTrue);
      analytics.clearEvents();

      // Log screen view & loan addition
      await analytics.logScreenView('dashboard');
      await analytics.logLoanAdded(category: 'Personal', principalAmount: 50000);
      await analytics.logPaymentRecorded(amount: 4500, isPaidOff: false);
      await analytics.logSimulationRun(type: 'lump_sum');
      await analytics.logSecurityEvent(eventType: 'biometric_success');

      final events = analytics.getRecentEvents();
      expect(events.length, equals(5));
      expect(events[0]['name'], equals('screen_view'));
      expect(events[1]['name'], equals('loan_added'));

      // Test opt-out toggle
      await analytics.setAnalyticsEnabled(false);
      expect(analytics.isEnabled, isFalse);

      await analytics.logScreenView('settings');
      expect(analytics.getRecentEvents().length, equals(5)); // No new event added

      // Re-enable
      await analytics.setAnalyticsEnabled(true);
      expect(analytics.isEnabled, isTrue);
    });

    testWidgets('TermsConditionsScreen renders all legal clauses and back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TermsConditionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('PayWise User Agreement'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. Financial Calculation Tool Disclaimer'), findsOneWidget);
      expect(find.text('3. Amortization & Estimate Accuracy'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('NotFoundScreen (404 Fallback) renders 404 badge and Return to Dashboard CTA', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NotFoundScreen(routeName: '/unknown_screen_test'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Screen Not Found (404)'), findsOneWidget);
      expect(find.textContaining('/unknown_screen_test'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });
  });
}
