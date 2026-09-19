# PayWise Comprehensive Bug & Quality Audit Report

**Audit Date**: September 19, 2026  
**Status**: Completed — Code changes paused awaiting user authorization  
**Scope**: Complete codebase inspection across all Dart source files (`lib/`), UI layouts, styling tokens, animations, screen transitions, state management, edge cases, dark/light theme compatibility, and typography down to single-character discrepancies.

---

## Executive Summary

An exhaustive line-by-line inspection of the PayWise application has been conducted. In accordance with user directives:
- **Zero code changes have been made.**
- **All detected anomalies**—spanning single-character typos, spacing/margin inconsistencies, animation hitches, dark mode contrast failures, layout overflow risks, and backend state edge cases—have been cataloged below with exact file paths, line references, root causes, and recommended solutions.

---

## Table of Contents
1. [Category 1: Single-Character Typos, Spelling, Casing & Brand Inconsistencies](#category-1-single-character-typos-spelling-casing--brand-inconsistencies)
2. [Category 2: Spacing, Margins, Padding & Layout Constraints](#category-2-spacing-margins-padding--layout-constraints)
3. [Category 3: Animations, Transitions & Page Switching Hitches](#category-3-animations-transitions--page-switching-hitches)
4. [Category 4: Dark Mode, Light Mode & Color Contrast Glitches](#category-4-dark-mode-light-mode--color-contrast-glitches)
5. [Category 5: Functional Logic, Calculation & State Integrity Bugs](#category-5-functional-logic-calculation--state-integrity-bugs)
6. [Summary Matrix & Next Steps](#summary-matrix--next-steps)

---

## Category 1: Single-Character Typos, Spelling, Casing & Brand Inconsistencies

### 1.1 Brand Name Lowercase Typo: "Paywise" vs "PayWise" (1-Character Inconsistency)
The official branding of the application is **PayWise** (capital "W", as reflected in the logo, app bar, notifications, and documentation). However, multiple strings across user-facing screens use the lowercase "w" (`Paywise`):
- **[welcome_screen.dart:129](file:///c:/Project_APP/Paywise/lib/Screens/welcome_screen.dart#L129)**: `Text("Paywise", ...)` — Splash branding title uses lowercase `w`.
- **[profile_screen.dart:67](file:///c:/Project_APP/Paywise/lib/Screens/profile_screen.dart#L67)**: `"Are you sure you want to log out of your Paywise account?"` — Dialog message uses lowercase `w`.
- **[edit_info_screen.dart:246](file:///c:/Project_APP/Paywise/lib/Screens/edit_info_screen.dart#L246)**: `"different Paywise account"` — Dialog description uses lowercase `w`.
- **[edit_info_screen.dart:309](file:///c:/Project_APP/Paywise/lib/Screens/edit_info_screen.dart#L309)**: `"Paywise account"` — Secondary dialog message uses lowercase `w`.
- **[edit_info_screen.dart:756](file:///c:/Project_APP/Paywise/lib/Screens/edit_info_screen.dart#L756)**: `"Sign out of Paywise"` — Tile title uses lowercase `w`.
- **[email_verification_screen.dart:70](file:///c:/Project_APP/Paywise/lib/Screens/email_verification_screen.dart#L70)**: `"Welcome to Paywise!"` — Email verification header uses lowercase `w`.
- **[email_verification_screen.dart:115](file:///c:/Project_APP/Paywise/lib/Screens/email_verification_screen.dart#L115)**: `"Welcome to Paywise!"` — Secondary verification header uses lowercase `w`.
> **Proposed Fix**: Replace all instances of `Paywise` with `PayWise` across all strings.

---

### 1.2 Inconsistent Title Casing vs Sentence Casing (1-Character Discrepancies)
- **[profile_screen.dart:645](file:///c:/Project_APP/Paywise/lib/Screens/profile_screen.dart#L645)**:  
  `title: 'Edit info'` uses a lowercase `'i'`, whereas every sibling settings tile uses strict Title Case (`'Change Password'`, `'Delete Account'`, `'Biometric App Lock'`).  
  > **Proposed Fix**: Change to `'Edit Info'`.
- **[profile_screen.dart:726](file:///c:/Project_APP/Paywise/lib/Screens/profile_screen.dart#L726)**:  
  Tile label reads `'Logout'` (one word, noun form), but the confirmation dialog title at line 62 reads `'Log Out'` (two words, verb form).  
  > **Proposed Fix**: Align tile label to `'Log Out'` to match the dialog and standard action button conventions.
- **[edit_info_screen.dart:720](file:///c:/Project_APP/Paywise/lib/Screens/edit_info_screen.dart#L720)**:  
  `title: 'Add account'` uses a lowercase `'a'`, while sibling actions use Title Case (`'Switch Account'`).  
  > **Proposed Fix**: Change to `'Add Account'`.
- **[email_verification_screen.dart:455](file:///c:/Project_APP/Paywise/lib/Screens/email_verification_screen.dart#L455)**:  
  Button reads `"Use a different account"` (sentence case) while the other action buttons on the screen use Title Case (`"Resend Verification Email"`, `"Submit Code & Enter Dashboard"`).  
  > **Proposed Fix**: Change to `"Use a Different Account"`.

---

### 1.3 Spelling Variation: "instalments" vs "Installment"
- **[info_screen.dart:534](file:///c:/Project_APP/Paywise/lib/Screens/info_screen.dart#L534)**:  
  `_formulaRow('n', 'Total number of monthly instalments (Tenure in Months)')` uses British spelling `"instalments"` (one "l").  
  In the same file at line 71:  
  `_GlossaryItem('Equated Monthly Installment (EMI)', ...)` uses American spelling `"Installment"` (double "l").  
  > **Proposed Fix**: Standardize to `"installments"` throughout the app.

---

### 1.4 Missing Currency Symbol in Education Screen Example
- **[info_screen.dart:545](file:///c:/Project_APP/Paywise/lib/Screens/info_screen.dart#L545)**:  
  `'Example: 5,00,000 at 8.5% for 5 years yields EMI of approximately 10,253 per month'`  
  The currency symbol (`₹`) is omitted before `5,00,000` and `10,253`. In all other cards and screens across the app, monetary figures are strictly prefixed with `₹`.  
  > **Proposed Fix**: Update text to `'Example: ₹5,00,000 at 8.5% for 5 years yields EMI of approximately ₹10,253 per month'`.

---

### 1.5 Outdated Application Name in PDF Export Header
- **[pdf_service.dart:26](file:///c:/Project_APP/Paywise/lib/services/pdf_service.dart#L26)**:  
  `pw.Text('Generated by Loan Management', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey))`  
  The generated PDF schedule displays `"Generated by Loan Management"` instead of `"Generated by PayWise"`. This leaks an old internal working project title into exported customer documents.  
  > **Proposed Fix**: Change text to `'Generated by PayWise'`.

---

### 1.6 Inconsistent Number Abbreviation Formatting: "k" vs "K" & Decimal Disparity
- **[dashboard_screen.dart:51](file:///c:/Project_APP/Paywise/lib/Screens/dashboard_screen.dart#L51)**:  
  `'₹${(amount / 1000).toStringAsFixed(1)}k'` -> Produces `₹25.0k` (1 decimal place, lowercase `k`).
- **[loan_analysis_screen.dart:37](file:///c:/Project_APP/Paywise/lib/Screens/loan_analysis_screen.dart#L37)**:  
  `'₹${(amount / 1000).toStringAsFixed(0)}k'` -> Produces `₹25k` (0 decimal places, lowercase `k`).  
  Furthermore, Lakhs and Crores use uppercase (`'L'`, `'Cr'`), while thousands use lowercase `'k'`.  
  > **Proposed Fix**: Standardize compact currency formatting logic across `dashboard_screen.dart` and `loan_analysis_screen.dart` to use consistent decimal precision and uppercase `'K'`.

---

### 1.7 Double Negative Display in Prepayment Interest Saved Card
- **[loan_analysis_screen.dart:328](file:///c:/Project_APP/Paywise/lib/Screens/loan_analysis_screen.dart#L328)**:  
  `"Interest Saved by Prepayments"` calculates positive savings (e.g., ₹1,200), but prepends a minus sign:  
  `"-${AppCurrency.format(saved)}"` -> Renders as `"-₹1,200"` in the summary banner, visually implying a penalty or loss rather than money saved.  
  > **Proposed Fix**: Remove the leading minus sign so it clearly reads `₹1,200` or `+₹1,200`.

---

### 1.8 Ungrammatical Due Date Badge Text
- **[dashboard_screen.dart:953](file:///c:/Project_APP/Paywise/lib/Screens/dashboard_screen.dart#L953)**:  
  When `daysLeft == 1`, badge text displays `🗓️ EMI Due: 1 Day`.  
  Compared to `⚡ EMI Due: Today` and `⚠️ EMI Overdue`, `1 Day` lacks context and grammar.  
  > **Proposed Fix**: Change to `🗓️ EMI Due: Tomorrow` or `🗓️ EMI Due: 1 Day Left`.

---

### 1.9 Grammatical Missing Hyphen in Account Deletion Screen
- **[delete_account_screen.dart:468](file:///c:/Project_APP/Paywise/lib/Screens/delete_account_screen.dart#L468)**:  
  Button reads `"Schedule Deletion (7 Days Grace Period)"`. As a compound modifier before "Grace Period", it should be `"7-Day Grace Period"` to match the card title above it.  
  > **Proposed Fix**: Change text to `"Schedule Deletion (7-Day Grace Period)"`.

---

### 1.10 Overly Blunt Form Validation Error Messages
- **[add_loan_screen.dart:776, 838, 858](file:///c:/Project_APP/Paywise/lib/Screens/add_loan_screen.dart#L776)**:  
  Error strings read: `"Not possible: Maximum loan amount is ₹100 Cr."`, `"Not possible: Maximum interest rate is 50%."`, `"Not possible: Maximum tenure is 40 years."`  
  Prefixing user validation errors with `"Not possible:"` is unpolished.  
  > **Proposed Fix**: Change to `"Maximum loan amount is ₹100 Cr."`, `"Maximum interest rate is 50%."`, `"Maximum tenure is 40 years."`.

---

## Category 2: Spacing, Margins, Padding & Layout Constraints

### 2.1 Double Redundant Spacer Widget (Accidental 60dp Gap)
- **[edit_info_screen.dart:769-770](file:///c:/Project_APP/Paywise/lib/Screens/edit_info_screen.dart#L769-L770)**:  
  ```dart
  const SizedBox(height: 20);
  const SizedBox(height: 40);
  ```
  Two consecutive `SizedBox` spacers are placed back-to-back before the bottom section, unintentionally stacking to create a 60dp dead gap.  
  > **Proposed Fix**: Remove `const SizedBox(height: 20);` to preserve intentional 40dp rhythm.

---

### 2.2 Massive 270dp Dead Scroll Gap at Bottom of Screens
- **[profile_screen.dart:782](file:///c:/Project_APP/Paywise/lib/Screens/profile_screen.dart#L782)**:  
  The `ListView` specifies:  
  `padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 150)`  
  AND its last child in the list is:  
  `const SizedBox(height: 120);`  
  Total dead scroll space at the bottom = **270dp** (nearly half the viewport height of blank space).
- **[info_screen.dart:45, 231](file:///c:/Project_APP/Paywise/lib/Screens/info_screen.dart#L45)**:  
  The `SingleChildScrollView` specifies:  
  `padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 150)`  
  AND the last child in the Column is:  
  `const SizedBox(height: 120);`  
  Total dead space = **270dp**.  
  > **Proposed Fix**: In both screens, remove the redundant `const SizedBox(height: 120);` since `150dp` bottom padding already accommodates the floating glass bottom navigation bar.

---

### 2.3 Inconsistent Horizontal Margins Across Sub-Screens (16dp vs Standard 8dp)
- **[loan_history_screen.dart:181](file:///c:/Project_APP/Paywise/lib/Screens/loan_history_screen.dart#L181)**:  
  Uses `padding: EdgeInsets.fromLTRB(16, totalTopPadding, 16, 100)`.  
  The rest of the core screens (`dashboard_screen.dart`, `loan_analysis_screen.dart`, `profile_screen.dart`, `welcome_screen.dart`) adhere to the standardized **8dp** horizontal margin required by the glass layout grid.  
  > **Proposed Fix**: Update horizontal padding to `8` (`EdgeInsets.fromLTRB(8, totalTopPadding, 8, 100)`) for uniform border alignments across all views.

---

### 2.4 RenderFlex Horizontal Overflow Risk in Quick Pay Modal
- **[dashboard_screen.dart:1086-1105](file:///c:/Project_APP/Paywise/lib/Screens/dashboard_screen.dart#L1086-L1105)**:  
  The header row of the Quick Pay modal bottom sheet is structured as:
  ```dart
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(...),
          const SizedBox(width: 10),
          Text('Quick Pay — ${loan.title}', ...), // No Expanded / Flexible!
        ],
      ),
      IconButton(...),
    ],
  )
  ```
  If a loan title exceeds ~16 characters (e.g. "Home Renovation Loan"), the inner row fails to wrap or truncate, triggering an unhandled yellow-and-black `A RenderFlex overflowed by xx pixels on the right` crash against the close `IconButton`.  
  > **Proposed Fix**: Wrap the inner title row or `Text` widget in `Expanded` with `overflow: TextOverflow.ellipsis` and `maxLines: 1`.

---

### 2.5 RenderFlex Vertical Overflow on Security Privacy Overlay for Small Screens
- **[main_shell.dart:300-575](file:///c:/Project_APP/Paywise/lib/Screens/main_shell.dart#L300-L575)**:  
  `_SecurityProtectedOverlay` uses a top-level `Column` containing multiple `Spacer()` widgets, large typography, and a 280px tall graphic without being wrapped in a `SingleChildScrollView`.  
  On mobile devices with screen heights < 680dp, in landscape mode, or when Android split-screen multitasking is enabled, this overlay overflows vertically with a RenderFlex error.  
  > **Proposed Fix**: Wrap the content inside `LayoutBuilder` + `SingleChildScrollView` or use `Flexible` widgets with constrained dimensions.

---

## Category 3: Animations, Transitions & Page Switching Hitches

### 3.1 Tab Switching Reverse-Slide Direction Inversion Glitch
- **[main_shell.dart:70-95](file:///c:/Project_APP/Paywise/lib/Screens/main_shell.dart#L70-L95)**:  
  When switching tabs in the bottom navbar, `AnimatedSwitcher` uses:
  ```dart
  final slideBeginOffset = _currentIndex >= _previousIndex
      ? const Offset(0.08, 0)
      : const Offset(-0.08, 0);
  ```
  `AnimatedSwitcher` applies the same transition builder to both incoming (0.0 -> 1.0) and outgoing (1.0 -> 0.0) widgets.  
  Because the outgoing widget runs the animation in reverse, it slides backwards *against* the direction of the tab navigation, causing an awkward visible snap/jerk whenever tabs are tapped in rapid succession.  
  > **Proposed Fix**: Decouple incoming and outgoing transitions or use a smooth pure `FadeTransition` without directional slide, or utilize a `PageView` with synchronized controller.

---

### 3.2 Screen State Loss and Scroll Reset on Tab Switching
- **[main_shell.dart:21-26, 96](file:///c:/Project_APP/Paywise/lib/Screens/main_shell.dart#L21-L26)**:  
  `_screens` are passed directly as children of `AnimatedSwitcher`:
  ```dart
  child: KeyedSubtree(
    key: ValueKey<int>(_currentIndex),
    child: _screens[_currentIndex],
  )
  ```
  Every time a user switches from Dashboard to Simulate or Learn and back, the Dashboard widget tree is completely unmounted and rebuilt from scratch.  
  Consequences:
  - User's scroll position on Dashboard is reset to top.
  - Active charts re-animate every time.
  - Local state in tabs is destroyed.  
  > **Proposed Fix**: Use `IndexedStack` or `PageView` with `AutomaticKeepAliveClientMixin` so tab states, scroll positions, and computations are preserved smoothly during navigation.

---

### 3.3 Abrupt FloatingActionButton (FAB) Disappearance (0ms Pop-In/Pop-Out)
- **[main_shell.dart:99](file:///c:/Project_APP/Paywise/lib/Screens/main_shell.dart#L99)**:  
  `floatingActionButton: _currentIndex == 0 ? FloatingActionButton(...) : null`  
  When switching from Dashboard (tab 0) to any other tab, the FAB snaps out of existence instantly with zero animation, contrasting starkly with the floating frosted bottom bar below it.  
  > **Proposed Fix**: Wrap the FAB in `AnimatedScale` or `AnimatedSwitcher` so it smoothly shrinks/fades in and out when changing tabs.

---

### 3.4 Floating Particles Re-seeded Randomly on Every Render Frame
- **[splash_screen.dart:392-396](file:///c:/Project_APP/Paywise/lib/Screens/splash_screen.dart#L392-L396)**:  
  In `_FloatingParticle.build()`:
  ```dart
  final rng = Random.secure();
  final baseX = rng.nextDouble() * size.width;
  final baseY = rng.nextDouble() * size.height;
  final dotSize = 3.0 + rng.nextDouble() * 5;
  final amplitude = 12.0 + rng.nextDouble() * 18;
  ```
  `_FloatingParticle` is a `StatelessWidget`. Every time the widget builds (e.g. on orientation change, screen resize, or theme change), completely new random coordinates are generated, causing floating dots to jump abruptly across the screen.  
  > **Proposed Fix**: Initialize particle positions and sizes once in `initState` of a `StatefulWidget` or pass deterministic seed offsets based on `index`.

---

### 3.5 Back-Stack Navigation Leak from Welcome Screen
- **[welcome_screen.dart:40, 48](file:///c:/Project_APP/Paywise/lib/Screens/welcome_screen.dart#L40)**:  
  ```dart
  Navigator.pushNamed(context, '/register');
  Navigator.pushNamed(context, '/login');
  ```
  When the user taps "Get Started" or "Sign In", the screen is pushed with `pushNamed`. If the user presses the system Android back gesture on the Login or Register screen, they are popped back to the Welcome screen—even though `hasSeenWelcome` was already set to `true`.  
  > **Proposed Fix**: Use `Navigator.pushReplacementNamed(context, '/login')` so the Welcome screen is cleared from the navigation back-stack.

---

## Category 4: Dark Mode, Light Mode & Color Contrast Glitches

### 4.1 Startup Light-Mode Dark Screen Flash
- **[main.dart:470-473](file:///c:/Project_APP/Paywise/lib/main.dart#L470-L473)**:  
  In `AuthWrapper`, while waiting for `SharedPreferences.getInstance()` to determine whether the user has seen the welcome screen:
  ```dart
  if (!snapshot.hasData) {
    return const Scaffold(
      backgroundColor: Color(0xFF10121D), // Hardcoded dark background!
      body: SizedBox.shrink(),
    );
  }
  ```
  On devices in Light Mode, the screen flashes a pure dark slate box (`#10121D`) for 100–250ms during startup before popping into the bright Light Theme Welcome/Login screen.  
  > **Proposed Fix**: Respect `Theme.of(context).scaffoldBackgroundColor` instead of a hardcoded dark color.

---

### 4.2 Low-Contrast Dark Amber Title on Dark Card in Educational Screen
- **[info_screen.dart:310-316](file:///c:/Project_APP/Paywise/lib/Screens/info_screen.dart#L310-L316)**:  
  In `_buildTrapCalloutCard()`:
  ```dart
  Text(
    'The Flat vs. Reducing Trap',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Color(0xFFB45309), // Hardcoded dark brown/amber!
    ),
  )
  ```
  While the body text below it checks `isDark` and switches to `Color(0xFFFDE68A)`, this title has a hardcoded dark amber `#B45309`. On Dark Mode cards (`Color(0xFFD97706)` with 0.12 alpha), this title is nearly unreadable due to low contrast.  
  > **Proposed Fix**: Update title color to `isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)`.

---

### 4.3 Invisible Calendar Suffix Icon in Add Loan Screen (Dark Mode)
- **[add_loan_screen.dart:650](file:///c:/Project_APP/Paywise/lib/Screens/add_loan_screen.dart#L650)**:  
  EMI payment date suffix icon has hardcoded:  
  `color: const Color(0xFF1E293B)` (very dark navy/slate).  
  On dark mode backgrounds (`Color(0xFF1E2238)`), this calendar icon becomes completely invisible.  
  > **Proposed Fix**: Set color adaptively: `isDark ? Colors.white70 : const Color(0xFF1E293B)`.

---

### 4.4 Hardcoded Light Pastel Icon Box in Delete Account Screen (Dark Mode Clashing)
- **[delete_account_screen.dart:521](file:///c:/Project_APP/Paywise/lib/Screens/delete_account_screen.dart#L521)**:  
  `_buildInfoBullet` icon container uses hardcoded:  
  `color: const Color(0xFFEEF2FF)` (light lavender/indigo).  
  In dark mode, it shines as an unstyled, stark bright square against the dark theme background.  
  > **Proposed Fix**: Set color dynamically: `isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEEF2FF)`.

---

### 4.5 Low-Contrast Outlined Button Border & Text in Delete Account Screen (Dark Mode)
- **[delete_account_screen.dart:461, 471](file:///c:/Project_APP/Paywise/lib/Screens/delete_account_screen.dart#L461)**:  
  The secondary action button uses hardcoded `#2A36B1` for both border and text:  
  `side: const BorderSide(color: Color(0xFF2A36B1), width: 1.5)`  
  `style: TextStyle(color: const Color(0xFF2A36B1), ...)`  
  On dark backgrounds, `#2A36B1` is dark blue with unacceptable contrast ratio (< 2.5:1).  
  > **Proposed Fix**: Set color to `isDark ? const Color(0xFF818CF8) : const Color(0xFF2A36B1)`.

---

### 4.6 Hardcoded Pastel Backgrounds in Simulation Refinancing Tab (Dark Mode Clashing)
- **[simulation_screen.dart:1746, 1750](file:///c:/Project_APP/Paywise/lib/Screens/simulation_screen.dart#L1746)**:  
  In `_RateBox`, the rate summary containers use hardcoded pastel colors:  
  `Color(0xFFFFEBEE)` (light pink) and `Color(0xFFE8F5E9)` (light mint green).  
  In Dark Mode, these pastel containers produce severe glare against the dark glass surface.  
  > **Proposed Fix**: Make them translucent in dark mode: `isDark ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFFFFEBEE)` and `isDark ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFE8F5E9)`.

---

### 4.7 Initial Device System Theme Preference Overwritten on App Launch
- **[settings_provider.dart:33](file:///c:/Project_APP/Paywise/lib/providers/settings_provider.dart#L33)**:  
  `final isDark = prefs.getBool('isDarkMode') ?? false;`  
  `_themeMode = isDark ? ThemeMode.dark : ThemeMode.light;`  
  `SettingsProvider` initializes with `_themeMode = ThemeMode.system`. However, as soon as `_loadSettings()` finishes, if `isDarkMode` was never explicitly toggled by the user, `prefs.getBool('isDarkMode')` returns `null`, which defaults to `false` and forces `ThemeMode.light`.  
  This overrides the user's OS system dark mode preference on fresh installs.  
  > **Proposed Fix**: Only set `_themeMode` if `prefs.containsKey('isDarkMode')` is true; otherwise keep `ThemeMode.system`.

---

## Category 5: Functional Logic, Calculation & State Integrity Bugs

### 5.1 Misleading Delete Transaction Dialog Description vs Actual Provider Behavior
- **[loan_details_screen.dart:377](file:///c:/Project_APP/Paywise/lib/Screens/loan_details_screen.dart#L377)** vs **[loan_provider.dart:369-416](file:///c:/Project_APP/Paywise/lib/providers/loan_provider.dart#L369-L416)**:  
  When a user taps to delete a payment transaction, the dialog states:  
  *"This only removes the record — the loan balance is managed by Firestore."*  
  **However**, `LoanProvider.deleteTransaction()` **actually reverses the payment** by adding the amount back to `outstandingBalance`, subtracting it from `totalPaid`, updating `isPaidOff`, and updating `lastPaymentDate`.  
  The dialog explicitly tells the user the balance will **not** change, when in reality the code **does** alter the balance! This misinforms users about their financial records.  
  > **Proposed Fix**: Update the dialog message to accurately reflect the functionality:  
  `"Deleting this record will reverse the payment, restoring ₹{amount} to your outstanding balance."`

---

### 5.2 List Order Scrambled on Undo Loan Deletion
- **[loan_provider.dart:429-435](file:///c:/Project_APP/Paywise/lib/providers/loan_provider.dart#L429-L435)**:  
  When a user taps "Undo" on the deletion toast:
  ```dart
  void cancelStageLoanDeletion(LoanModel loan) {
    _stagedForDeletionIds.remove(loan.id);
    if (!_loans.any((l) => l.id == loan.id)) {
      _loans.add(loan); // Appends to the END!
      notifyListeners();
    }
  }
  ```
  `_loans.add(loan)` places the restored loan at the very bottom of the user's list. If the user had 5 loans and undid deletion of the 1st one, it jumps to position 5, causing visual disorientation until a new Firestore snapshot fires.  
  > **Proposed Fix**: Reinsert the loan at its previous index or preserve sorting order (e.g. by `startDate` or `id`).

---

### 5.3 Potential Crash Hazard in Payment Date Picker on Clock Drift / Future Date
- **[loan_details_screen.dart:940](file:///c:/Project_APP/Paywise/lib/Screens/loan_details_screen.dart#L940)**:  
  In `_showPaymentBottomSheet()`, `showDatePicker` is called with:
  ```dart
  initialDate: selectedPaymentDate,
  firstDate: DateTime(2000),
  lastDate: DateTime.now(),
  ```
  While line 852 guards `selectedPaymentDate` during bottom sheet opening, if user device time syncs or shifts slightly while the sheet is open, or if `selectedPaymentDate` is milliseconds ahead of `DateTime.now()`, Flutter throws an unhandled assertion crash: `initialDate must be on or before lastDate`.  
  > **Proposed Fix**: Clamp `initialDate`:  
  `initialDate: selectedPaymentDate.isAfter(DateTime.now()) ? DateTime.now() : selectedPaymentDate`.

---

### 5.4 Division by Zero / Infinity in Loan Provider Calculation
- **[loan_provider.dart:306-313](file:///c:/Project_APP/Paywise/lib/providers/loan_provider.dart#L306-L313)**:  
  In `addLoan()`:
  ```dart
  if (loan.interestRate > 0) {
    loan.emiAmount = (loan.principalAmount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  } else {
    loan.emiAmount = loan.principalAmount / loan.tenureMonths;
  }
  ```
  If `loan.tenureMonths == 0`, `(pow(1 + r, 0) - 1) == 0` or `principalAmount / 0`, yielding `double.infinity` or `NaN`, which causes Firestore document write failures or crashes when rendering charts.  
  > **Proposed Fix**: Add guard: `if (loan.tenureMonths <= 0) throw Exception("Loan tenure must be at least 1 month.");`.

---

### 5.5 False Promise in Switch Account Dialog
- **[edit_info_screen.dart:246-265](file:///c:/Project_APP/Paywise/lib/Screens/edit_info_screen.dart#L246-L265)**:  
  The "Switch Account" dialog states:  
  *"Your current session will be safely preserved."*  
  However, the button action immediately calls:
  ```dart
  await _authService.signOut();
  loanProvider.clearUserData();
  ```
  Firebase Auth does not support multi-account session preservation on mobile. Tapping this completely logs the user out and wipes local session data. Promising that the session is "safely preserved" is misleading.  
  > **Proposed Fix**: Update dialog text to: `"You will be logged out of your current account to sign in with another account."`

---

### 5.6 Notification Service Skips Current-Month Overdue Reminder on Due Date
- **[notification_service.dart:125-135](file:///c:/Project_APP/Paywise/lib/services/notification_service.dart#L125-L135)**:  
  In `scheduleAll5EmiReminders()`:
  ```dart
  DateTime targetDueDate = DateTime(targetYear, targetMonth, safeDueDay, 9, 0);
  if (targetDueDate.isBefore(now)) {
    // Advance to next month if target date for this month has already passed
    targetMonth += 1;
    ...
  }
  ```
  If this method runs on the due date at 2:00 PM (`targetDueDate` was 9:00 AM today), `targetDueDate.isBefore(now)` evaluates to `true`.  
  This immediately shifts `targetDueDate` to **next month**, meaning Reminder #5 (`Overdue alert: targetDueDate + 1 day at 11:00 AM`) will **not** trigger tomorrow for this month's payment! It gets postponed by 30 days.  
  > **Proposed Fix**: Only advance `targetDueDate` to next month if the overdue window (`targetDueDate.add(const Duration(days: 1))`) has also elapsed.

---

### 5.7 Inconsistent All-Caps Transformation on Bank Lender Input
- **[add_loan_screen.dart:345](file:///c:/Project_APP/Paywise/lib/Screens/add_loan_screen.dart#L345)**:  
  `_lenderController.text.trim().toUpperCase()` forces every lender name into ALL CAPS (e.g. "STATE BANK OF INDIA (SBI)").  
  However, the bank suggestion list uses standard Title Case ("State Bank of India (SBI)"). This creates mismatched casing throughout loan cards and transaction receipts.  
  > **Proposed Fix**: Store lender name with natural casing matching user input or bank suggestions instead of forced `.toUpperCase()`.

---

### 5.8 PDF Amortization Date Calculations Unanchored from Loan Start Date
- **[pdf_service.dart:52](file:///c:/Project_APP/Paywise/lib/services/pdf_service.dart#L52)**:  
  ```dart
  final date = DateTime.now().add(Duration(days: 30 * row.month));
  ```
  The amortization schedule PDF computes monthly repayment dates starting from `DateTime.now()` rather than `loan.startDate`. For existing loans started in the past or planned for next month, the dates in the PDF are inaccurate.  
  > **Proposed Fix**: Anchor dates to loan start:  
  `final date = DateTime(loan.startDate.year, loan.startDate.month + row.month, loan.startDate.day);`.

---

### 5.9 Prepayment Simulator Interest Calculation Timing
- **[simulation_screen.dart:894-905](file:///c:/Project_APP/Paywise/lib/Screens/simulation_screen.dart#L894-L905)**:  
  In `_LumpSumTab`:
  ```dart
  double interest = balance * r;
  double principal = emi - interest;
  ...
  balance -= (principal + extraLump);
  ```
  Monthly interest is computed on the balance *before* subtracting the lump-sum prepayment. If a user enters a lump-sum that completely clears the remaining balance in month `m`, full period interest is still charged on the pre-payoff balance for that month.  
  > **Proposed Fix**: If prepayment occurs at the beginning of the period or clears the loan, apply prepayment to principal prior to computing interest or prorate accordingly.

---

### 5.10 Immediate Permanent Deletion on Tapping Toast Close Icon
- **[undo_toast.dart:90-107](file:///c:/Project_APP/Paywise/lib/widgets/undo_toast.dart#L90-L107)**:  
  When the Undo delete toast appears, tapping the `x` (close) icon immediately executes `loanProvider.confirmPermanentDelete(loan.id)`.  
  Users frequently tap `x` simply to dismiss visual clutter without intending to bypass their remaining 8-second grace period.  
  > **Proposed Fix**: Make tapping `x` merely dismiss the UI overlay while allowing the existing background timer to complete its remaining countdown before permanent deletion.

---

## Summary Matrix & Next Steps

| ID | Location | Issue Type | Severity | Description |
|:---|:---|:---|:---|:---|
| **1.1** | Multiple screens (7 instances) | Typo | Low | Brand name written as "Paywise" with lowercase "w" instead of "PayWise" |
| **1.2** | Profile, Edit Info, Email Verification | Casing | Low | "Edit info", "Logout", "Add account" casing mismatches |
| **1.3** | `info_screen.dart:534` | Spelling | Low | "instalments" vs "Installment" |
| **1.4** | `info_screen.dart:545` | Formatting | Low | Missing `₹` symbol in calculation example |
| **1.5** | `pdf_service.dart:26` | Branding | Medium | PDF header says "Generated by Loan Management" |
| **1.6** | Dashboard & Analysis | Formatting | Low | Inconsistent "k" vs "K" and decimal precision |
| **1.7** | `loan_analysis_screen.dart:328` | UI Math | Low | Double negative sign on interest saved (`-₹1,200`) |
| **1.8** | `dashboard_screen.dart:953` | Grammar | Low | "EMI Due: 1 Day" awkward phrasing |
| **1.9** | `delete_account_screen.dart:468` | Grammar | Low | "7 Days Grace Period" missing hyphen |
| **1.10** | `add_loan_screen.dart:776+` | UX Writing | Low | "Not possible:" prefix in validation messages |
| **2.1** | `edit_info_screen.dart:769-770` | Layout | Low | Double consecutive SizedBox (20 + 40 = 60dp gap) |
| **2.2** | Profile & Info screens | Spacing | Medium | 270dp dead blank scroll padding at bottom |
| **2.3** | `loan_history_screen.dart:181` | Layout | Low | 16dp horizontal margin instead of standard 8dp |
| **2.4** | `dashboard_screen.dart:1086` | Overflow | **High** | Quick Pay title overflows offscreen for long loan names |
| **2.5** | `main_shell.dart:300` | Overflow | Medium | Security overlay RenderFlex overflow on small screens |
| **3.1** | `main_shell.dart:70` | Animation | Medium | Tab switching slide direction reverse glitch |
| **3.2** | `main_shell.dart:96` | State/UX | Medium | Tab switching destroys scroll state & causes re-renders |
| **3.3** | `main_shell.dart:99` | Transition | Low | FAB vanishes/appears abruptly with 0ms transition |
| **3.4** | `splash_screen.dart:392` | Animation | Low | Floating particles re-seed randomly on every frame |
| **3.5** | `welcome_screen.dart:40` | Navigation | Medium | Back button from login/register pops back into welcome |
| **4.1** | `main.dart:470` | Theming | Medium | Startup flashes dark background on light mode devices |
| **4.2** | `info_screen.dart:310` | Contrast | Medium | Hardcoded dark amber title unreadable in Dark Mode |
| **4.3** | `add_loan_screen.dart:650` | Visibility | Medium | Calendar suffix icon invisible in Dark Mode |
| **4.4** | `delete_account_screen.dart:521`| Theming | Low | Unstyled bright pastel box in Dark Mode |
| **4.5** | `delete_account_screen.dart:461`| Contrast | Medium | Button border & text unreadable in Dark Mode |
| **4.6** | `simulation_screen.dart:1746` | Theming | Low | Pastel pink/green rate boxes glare in Dark Mode |
| **4.7** | `settings_provider.dart:33` | Logic | Medium | System Theme Mode ignored on initial install |
| **5.1** | `loan_details_screen.dart:377` | Logic/UX | **High** | Delete txn dialog says balance won't change, but it does |
| **5.2** | `loan_provider.dart:429` | State | Medium | Restored loan on Undo jumps to bottom of list |
| **5.3** | `loan_details_screen.dart:940` | Crash Hazard | **High** | DatePicker crash if initialDate is ahead of lastDate |
| **5.4** | `loan_provider.dart:306` | Math | Medium | Division by zero if tenureMonths is 0 |
| **5.5** | `edit_info_screen.dart:246` | Logic/UX | Medium | "Session preserved" dialog promise is untrue |
| **5.6** | `notification_service.dart:125`| Logic | Medium | Skips current month overdue reminder on due date afternoon |
| **5.7** | `add_loan_screen.dart:345` | Formatting | Low | Lender name forced into ALL CAPS |
| **5.8** | `pdf_service.dart:52` | Calculation | Medium | PDF dates anchored to DateTime.now() instead of loan start |
| **5.9** | `simulation_screen.dart:894` | Calculation | Low | Lump sum payoff month interest timing |
| **5.10**| `undo_toast.dart:90` | Logic/UX | Medium | Tapping 'x' on toast triggers immediate permanent deletion |

---

### User Directive Compliance
As instructed:
> *"only make md file for bugs the if i tell you to souve that bug than & than do change in code othervise dont"*

**No source files have been changed.** Please review the report above and indicate which bugs (or categories) you would like resolved.
