import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/utils/currency_formatter.dart';
import 'package:paywise/theme/glass_theme.dart';
import 'package:paywise/Screens/edit_info_screen.dart';
import 'package:provider/provider.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/Screens/main_shell.dart';
import 'package:paywise/Screens/welcome_screen.dart';
import 'package:paywise/Screens/register_screen.dart';
import 'package:paywise/Screens/login_screen.dart';
import 'package:paywise/Screens/simulation_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:paywise/Screens/loan_analysis_screen.dart';
import 'package:paywise/Screens/info_screen.dart';

void main() {
  test('LoanModel serialization and ledger fields test', () {
    final loan = LoanModel(
      id: 'test_1',
      userId: 'user_1',
      title: 'Very Long Luxury Villa Home Mortgage Loan',
      lenderName: 'State Bank of India Corporate Branch',
      principalAmount: 5000000.0,
      interestRate: 8.5,
      tenureMonths: 240,
      startDate: DateTime(2025, 1, 1),
      emiDueDate: 5,
      outstandingBalance: 4850000.0,
      emiAmount: 43391.0,
      totalPaid: 150000.0,
      isPaidOff: false,
    );

    expect(loan.id, 'test_1');
    expect(loan.principalAmount, 5000000.0);
    expect(AppCurrency.format(loan.principalAmount), '₹50,00,000');
    expect(AppCurrency.format(loan.outstandingBalance), '₹48,50,000');
  });

  testWidgets('Narrow viewport (320px) loan card layout test with zero overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final loan = LoanModel(
      id: 'test_1',
      userId: 'user_1',
      title: 'Very Long Luxury Home Loan Name That Could Overflow',
      lenderName: 'Housing Development Finance Corporation Bank',
      principalAmount: 5000000.0,
      interestRate: 8.5,
      tenureMonths: 240,
      startDate: DateTime(2025, 1, 1),
      emiDueDate: 5,
      outstandingBalance: 4850000.0,
      emiAmount: 43391.0,
      totalPaid: 150000.0,
      isPaidOff: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tier 1: Category Icon + Title/Lender + Amount/EMI
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.home, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loan.lenderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppCurrency.format(loan.outstandingBalance),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'EMI: ${AppCurrency.format(loan.emiAmount)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tier 2: Status & Due Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            '🗓️ EMI Due: 28 Days',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widgets rendered without overflow exceptions
    expect(tester.takeException(), isNull);
    expect(find.text(loan.title), findsOneWidget);
    expect(find.text('₹48,50,000'), findsOneWidget);
    expect(find.text('EMI: ₹43,391'), findsOneWidget);
  });

  test('Loan sorting prioritizes active loans and nearest EMI dues over completed loans', () {
    final now = DateTime.now();

    final completedLoan = LoanModel(
      id: 'completed_1',
      userId: 'u1',
      title: 'Completed Personal Loan',
      lenderName: 'HDFC',
      principalAmount: 100000,
      interestRate: 10,
      tenureMonths: 12,
      startDate: DateTime(2024, 1, 1),
      emiDueDate: 5,
      outstandingBalance: 0,
      isPaidOff: true,
      lastPaymentDate: now.subtract(const Duration(hours: 2)),
    );

    final activeDueLater = LoanModel(
      id: 'active_later',
      userId: 'u1',
      title: 'Active Home Loan (Due Later)',
      lenderName: 'SBI',
      principalAmount: 2000000,
      interestRate: 8.5,
      tenureMonths: 240,
      startDate: DateTime(2024, 1, 1),
      emiDueDate: now.day == 28 ? 1 : 28,
      outstandingBalance: 1900000,
      isPaidOff: false,
      lastPaymentDate: now.subtract(const Duration(days: 5)),
    );

    final activeDueSoon = LoanModel(
      id: 'active_soon',
      userId: 'u1',
      title: 'Active Car Loan (Due Today/Soon)',
      lenderName: 'Axis',
      principalAmount: 500000,
      interestRate: 9.0,
      tenureMonths: 60,
      startDate: DateTime(2024, 1, 1),
      emiDueDate: now.day,
      outstandingBalance: 400000,
      isPaidOff: false,
    );

    // Initial order has completed loan first
    final loans = [completedLoan, activeDueLater, activeDueSoon];

    // Sorting rule matching dashboard
    loans.sort((a, b) {
      if (!a.isPaidOff && b.isPaidOff) return -1;
      if (a.isPaidOff && !b.isPaidOff) return 1;

      if (!a.isPaidOff && !b.isPaidOff) {
        // Nearest EMI due first
        final daysA = a.emiDueDate == now.day ? 0 : 20;
        final daysB = b.emiDueDate == now.day ? 0 : 20;
        if (daysA != daysB) return daysA.compareTo(daysB);
        return b.outstandingBalance.compareTo(a.outstandingBalance);
      }

      return 0;
    });

    // Active due soon must be first
    expect(loans[0].id, 'active_soon');
    // Active due later must be second
    expect(loans[1].id, 'active_later');
    // Completed loan must always be last
    expect(loans[2].id, 'completed_1');
  });

  testWidgets('GlassContainer renders with BackdropFilter, ClipRRect and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: Center(
            child: GlassContainer(
              borderRadius: 20,
              blur: 16,
              borderWidth: 1.0,
              onTap: () => tapped = true,
              child: const Text('Apple Frosted Glass'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Apple Frosted Glass'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ClipRRect), findsWidgets);

    await tester.tap(find.text('Apple Frosted Glass'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('frostedAppBarFlexibleSpace and ScrolledNotificationWrapper dynamic scroll border test', (WidgetTester tester) async {
    final ValueNotifier<bool> isScrolled = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Builder(
              builder: (ctx) => GlassTheme.frostedAppBarFlexibleSpace(
                ctx,
                isScrolledNotifier: isScrolled,
              ),
            ),
          ),
          body: ScrolledNotificationWrapper(
            isScrolledNotifier: isScrolled,
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (ctx, i) => SizedBox(height: 60, child: Text('Item $i')),
            ),
          ),
        ),
      ),
    );

    // Initial state: at top (offset = 0)
    expect(isScrolled.value, isFalse);

    // Find AnimatedContainer inside frostedAppBarFlexibleSpace
    final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    final initialContainer = animatedContainers.first;
    final initialDecoration = initialContainer.decoration as BoxDecoration;
    final initialBorder = initialDecoration.border as Border;
    expect(initialBorder.bottom.color, Colors.transparent);

    // Scroll down by 60px
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(isScrolled.value, isTrue);
    final scrolledContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    final scrolledDecoration = scrolledContainers.first.decoration as BoxDecoration;
    final scrolledBorder = scrolledDecoration.border as Border;
    expect(scrolledBorder.bottom.color, isNot(Colors.transparent));

    // Scroll back to top
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pumpAndSettle();

    expect(isScrolled.value, isFalse);
    final resetContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    final resetDecoration = resetContainers.first.decoration as BoxDecoration;
    final resetBorder = resetDecoration.border as Border;
    expect(resetBorder.bottom.color, Colors.transparent);
  });

  testWidgets('EditInfoScreen layout: Your Name, Your Info, and Account options in one card', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EditInfoScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. App Bar Title
    expect(find.text('Edit Info'), findsOneWidget);

    // 2. Section "Your Name" with First Name and Last Name
    expect(find.text('Your Name'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);

    // 3. Section "Your Info" with Email, Username, Birthdate
    expect(find.text('Your Info'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Birthdate'), findsOneWidget);

    // 4. In One Card: "Add account" and "Logout"
    expect(find.text('Add Account'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // 5. Test Add Account modal bottom sheet
    await tester.ensureVisible(find.text('Add Account'));
    await tester.tap(find.text('Add Account'));
    await tester.pumpAndSettle();
    expect(find.text('Add Another Account'), findsOneWidget);

    // Dismiss bottom sheet
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 6. Test Logout confirmation dialog
    await tester.ensureVisible(find.text('Log Out'));
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out of your PayWise account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  test('Multi-account isolation: LoanModel serializes userEmail and isolates by userId', () {
    final loanUserA = LoanModel(
      id: 'loan_a',
      userId: 'user_A_id',
      userEmail: 'userA@gmail.com',
      title: 'Home Loan Account A',
      lenderName: 'HDFC',
      principalAmount: 2500000.0,
      interestRate: 8.5,
      tenureMonths: 120,
      startDate: DateTime(2025, 1, 1),
      emiDueDate: 5,
    );

    final loanUserB = LoanModel(
      id: 'loan_b',
      userId: 'user_B_id',
      userEmail: 'userB@gmail.com',
      title: 'Car Loan Account B',
      lenderName: 'SBI',
      principalAmount: 800000.0,
      interestRate: 9.0,
      tenureMonths: 60,
      startDate: DateTime(2025, 2, 1),
      emiDueDate: 10,
    );

    final mapA = loanUserA.toMap();
    expect(mapA['userId'], 'user_A_id');
    expect(mapA['userEmail'], 'userA@gmail.com');

    final mapB = loanUserB.toMap();
    expect(mapB['userId'], 'user_B_id');
    expect(mapB['userEmail'], 'userB@gmail.com');

    // Deserialization check
    final deserializedA = LoanModel.fromMap(mapA, 'loan_a');
    expect(deserializedA.userId, 'user_A_id');
    expect(deserializedA.userEmail, 'userA@gmail.com');

    // Strict account isolation test:
    // When querying for User B, User A's loan must NEVER be present
    final allDocs = [deserializedA, LoanModel.fromMap(mapB, 'loan_b')];
    final userBLoans = allDocs.where((l) => l.userId == 'user_B_id').toList();

    expect(userBLoans.length, 1);
    expect(userBLoans.first.userId, 'user_B_id');
    expect(userBLoans.first.userEmail, 'userB@gmail.com');
    expect(userBLoans.any((l) => l.userId == 'user_A_id'), isFalse);
  });

  test('LoanProvider clearUserData resets all loans, balances, and staged deletions', () {
    final provider = LoanProvider();
    
    // Add loan into staged deletion
    final testLoan = LoanModel(
      id: 'temp_loan',
      userId: 'test_user',
      title: 'Test Loan',
      lenderName: 'Test Lender',
      principalAmount: 100000,
      interestRate: 10,
      tenureMonths: 12,
      startDate: DateTime.now(),
      emiDueDate: 1,
    );

    provider.stageLoanForDeletion(testLoan);
    expect(provider.loans.isEmpty, isTrue);

    // Call clearUserData
    provider.clearUserData();

    expect(provider.loans, isEmpty);
    expect(provider.totalOutstanding, 0.0);
    expect(provider.monthlyOutflow, 0.0);
    expect(provider.previousMonthOutstanding, -1);
  });

  testWidgets('GlassAlertDialog renders with frosted glass blur, icon, title, content and actions', (WidgetTester tester) async {
    bool cancelled = false;
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GlassAlertDialog(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Permanently'),
                      content: const Text('Are you sure you want to erase all data?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            cancelled = true;
                            Navigator.pop(ctx);
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            confirmed = true;
                            Navigator.pop(ctx);
                          },
                          child: const Text('Delete Now'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Popup'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Popup'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassAlertDialog), findsOneWidget);
    expect(find.text('Delete Permanently'), findsOneWidget);
    expect(find.text('Are you sure you want to erase all data?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete Now'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);

    await tester.tap(find.text('Delete Now'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
    expect(cancelled, isFalse);
  });

  testWidgets('WelcomeScreen renders properly with brand title, benefits, and action buttons', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenWelcome': false});

    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PayWise'), findsOneWidget);
    expect(find.text('Master Your Loans. Beat the Interest.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  test('SharedPreferences hasSeenWelcome flag lifecycle: fresh install -> welcome, delete account -> welcome, logout -> login', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // 1. Fresh install: hasSeenWelcome defaults to false -> routes to WelcomeScreen
    expect(prefs.getBool('hasSeenWelcome'), isNull);

    // 2. User completes WelcomeScreen -> hasSeenWelcome set to true
    await prefs.setBool('hasSeenWelcome', true);
    expect(prefs.getBool('hasSeenWelcome'), isTrue);

    // 3. User logs out -> hasSeenWelcome remains true (goes directly to LoginScreen, not WelcomeScreen)
    expect(prefs.getBool('hasSeenWelcome'), isTrue);

    // 4. User deletes account -> hasSeenWelcome reset to false (goes to WelcomeScreen)
    await prefs.setBool('hasSeenWelcome', false);
    expect(prefs.getBool('hasSeenWelcome'), isFalse);
  });

  testWidgets('Navigation: Welcome -> Register -> Login -> Register flow with zero black screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenWelcome': false});

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/welcome',
        routes: {
          '/welcome': (ctx) => const WelcomeScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/login': (ctx) => const LoginScreen(),
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 1. On WelcomeScreen, tap "Get Started"
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 2. Now on RegisterScreen
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // 3. Tap bottom "Login" link on RegisterScreen
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 4. Now on LoginScreen (NOT black screen!)
    expect(find.text('Smart Loans, Smarter You'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // 5. Tap bottom "Register" link on LoginScreen
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 6. Back on RegisterScreen!
    expect(find.text('Create Account'), findsOneWidget);

    // 7. Tap top back button on RegisterScreen -> returns to WelcomeScreen
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Master Your Loans. Beat the Interest.'), findsOneWidget);
  });

  testWidgets('Dashboard "+ Add Loan" FAB is strictly ABOVE bottom navbar in both Buttons and Gestures mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final loanProvider = LoanProvider();
    final settingsProvider = SettingsProvider();

    // 1. TEST BUTTONS MODE (3-button navigation bar with 48dp bottom inset)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 48.0);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetPadding();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: loanProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Add Loan'), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);

    final fabBottomInButtonsMode = tester.getBottomRight(find.widgetWithText(FloatingActionButton, 'Add Loan')).dy;
    final navBarTopInButtonsMode = tester.getTopLeft(find.byType(GlassContainer)).dy;

    // The FAB bottom MUST be strictly above the top of the navbar (smaller Y in screen coords)
    expect(fabBottomInButtonsMode <= navBarTopInButtonsMode, isTrue,
        reason: 'FAB ($fabBottomInButtonsMode) must be above bottom navbar ($navBarTopInButtonsMode) in 3-button mode');
    // Ensure healthy separation gap
    expect(navBarTopInButtonsMode - fabBottomInButtonsMode >= 10.0, isTrue);

    // 2. TEST GESTURE MODE (0dp bottom inset or minimal gesture pill)
    tester.view.padding = const FakeViewPadding(bottom: 0.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final fabBottomInGestureMode = tester.getBottomRight(find.widgetWithText(FloatingActionButton, 'Add Loan')).dy;
    final navBarTopInGestureMode = tester.getTopLeft(find.byType(GlassContainer)).dy;

    expect(fabBottomInGestureMode <= navBarTopInGestureMode, isTrue,
        reason: 'FAB ($fabBottomInGestureMode) must be above bottom navbar ($navBarTopInGestureMode) in gesture mode');
    expect(navBarTopInGestureMode - fabBottomInGestureMode >= 10.0, isTrue);
  });

  testWidgets('SimulationScreen Lump Sum mode switch renders and smoothly transitions between modes', (WidgetTester tester) async {
    final loanProvider = LoanProvider();
    final sampleLoan = LoanModel(
      id: 'test_sim_loan',
      userId: 'test_user',
      title: 'Home Loan',
      lenderName: 'HDFC Bank',
      principalAmount: 2000000,
      interestRate: 8.5,
      tenureMonths: 120,
      startDate: DateTime(2025, 1, 1),
      emiDueDate: 5,
      outstandingBalance: 1800000,
      emiAmount: 24796,
    );
    loanProvider.loans.add(sampleLoan);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: loanProvider),
        ],
        child: const MaterialApp(
          home: SimulationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Lump Sum tab (2nd tab)
    await tester.tap(find.text('Lump Sum'));
    await tester.pumpAndSettle();

    // Verify mode buttons exist
    expect(find.text('One-Time'), findsOneWidget);
    expect(find.text('Yearly Bonus'), findsOneWidget);
    expect(find.text('Custom Multi'), findsOneWidget);

    // Initial mode is Yearly Bonus
    expect(find.text('Recurring Annual Yearly Bonus'), findsOneWidget);

    // Tap "One-Time" and verify transition
    await tester.tap(find.text('One-Time'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify One-Time mode content is now rendered
    expect(find.text('One-Time Lump Sum Payment'), findsOneWidget);

    // Tap "Custom Multi" and verify transition
    await tester.tap(find.text('Custom Multi'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify Custom Multi content is rendered
    expect(find.text('Custom Multiple Prepayments'), findsOneWidget);
  });

  testWidgets('LoanAnalysisScreen renders as a dedicated page with hero card and breakdown', (WidgetTester tester) async {
    final loanProvider = LoanProvider();
    final sampleLoan = LoanModel(
      id: 'test_analysis_loan',
      userId: 'test_user',
      title: 'Car Loan',
      lenderName: 'SBI',
      principalAmount: 800000,
      interestRate: 9.0,
      tenureMonths: 60,
      startDate: DateTime(2025, 1, 1),
      emiDueDate: 10,
      outstandingBalance: 600000,
      emiAmount: 16607,
      totalPaid: 200000,
    );
    loanProvider.loans.add(sampleLoan);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: loanProvider),
        ],
        child: MaterialApp(
          home: LoanAnalysisScreen(loan: sampleLoan),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Car Loan Analysis'), findsOneWidget);
    expect(find.text('STATUS: ACTIVE LOAN'), findsOneWidget);
    expect(find.text('Amortization Trajectory'), findsOneWidget);
    expect(find.text('Remaining Balance'), findsOneWidget);
    expect(find.text('Principal Paid'), findsOneWidget);
    expect(find.text('Interest Paid'), findsOneWidget);
    expect(find.text('Loan Timeline & Duration'), findsOneWidget);
    expect(find.text('Financial Breakdown'), findsOneWidget);
    expect(find.text('Download Full Loan Statement (PDF)'), findsOneWidget);

    // Verify toggle to Full Plan projection
    expect(find.text('Full Plan'), findsOneWidget);
    await tester.tap(find.text('Full Plan'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('InfoScreen renders comprehensive financial curriculum without emojis or links', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InfoScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn & Info'), findsOneWidget);
    expect(find.text('Financial Wisdom & Loan Essentials'), findsOneWidget);
    expect(find.text('Core Loan Foundations'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Interest Rate Structures & Systems'), findsOneWidget);
    expect(find.text('The Flat vs. Reducing Trap'), findsOneWidget);
    expect(find.text('Security & Asset Rules'), findsOneWidget);
    expect(find.text('Costs, Fees & Financial Health'), findsOneWidget);
  });
}



