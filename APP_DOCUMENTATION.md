# PayWise — Comprehensive Technical & Architecture Documentation

This document provides a complete, exhaustive technical specification of the **PayWise** mobile application. It covers architecture, technology stack, backend infrastructure, color systems, UI/UX animations, financial engines, security, state management, toast notifications, launcher icons, and a **page-by-page typography, text size, and color token breakdown**.

---

## 1. Executive Summary & Overview

* **Application Name**: PayWise
* **Package / Namespace**: `com.paywise.app`
* **App Goal**: A modern, premium loan management and financial simulation platform designed to help users track active loans, monitor debt outlays, run real-time repayment simulations (extra EMI, recurring annual bonus, custom multi-lump sum, refinancing), generate PDF amortization schedules, and optimize total interest paid.
* **Target Platforms**: Android & iOS (Tested on Android API 34/35 & iOS 17+ devices).

---

## 2. Technology Stack & Dependencies

### Core Framework & Language
* **Framework**: Flutter (v3.31+)
* **Language**: Dart (v3.0+)
* **UI Architecture**: Material 3 Design System with custom dark/light theme tokens and a custom floating pill navigation shell.

### External Packages (`pubspec.yaml`)
1. **State Management**: `provider` (MultiProvider with `Selector`, `ChangeNotifierProvider`)
2. **Backend & Authentication**:
   * `firebase_core` (v3.x)
   * `firebase_auth` (v5.x)
   * `cloud_firestore` (v5.x)
3. **Data Persistence & Local Storage**: `shared_preferences`
4. **Biometric Security**: `local_auth` (Fingerprint / Face ID authentication)
5. **Charts & Data Visualization**: `fl_chart` (Custom Donut/Pie chart rendering)
6. **Calendar & Scheduling**: `table_calendar`
7. **Local Notifications**: `flutter_local_notifications`
8. **PDF Generation & Printing**: `pdf`, `printing`
9. **Launcher Icons**: `flutter_launcher_icons`
10. **Formatting & Utilities**: `intl` (NumberFormat currency formatting in INR ₹, DateFormat)

---

## 3. Design System & Global Color Tokens

PayWise utilizes a curated **Deep Navy Blue & Royal Blue** design palette tailored for light and dark modes.

### Primary Color Tokens
* **Primary Deep Navy Accent**: `Color(0xFF1E3C72)`
* **Primary Royal Blue Accent**: `Color(0xFF2A5298)`
* **Primary Indigo Accent**: `Color(0xFF3B4CCA)` / `Color(0xFF2A36B1)`
* **Hero Card Gradient**: `LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)])` (Deep Navy to Royal Blue)
* **Header Action Gradient**: `LinearGradient(colors: [Color(0xFF2A36B1), Color(0xFF3B4CCA)])`
* **Light Mode Background**: `#F7F8FE` / `#F8F9FA` (Soft off-white)
* **Light Mode Card Surface**: `#FFFFFF` (Pure white)
* **Light Mode Soft Container Accent**: `#EEF2FF` / `#EBF1F9` (Soft Navy/Indigo tint)
* **Dark Mode Background**: `#0D0F1B` / `#121212` (True dark background)
* **Dark Mode Card Surface**: `#16192A` / `#1E1E2C` (Elevated dark surface)
* **Dark Mode Soft Container Accent**: `Color(0xFF1E3C72).withValues(alpha: 0.25)`

### Functional & Toast Color Tokens
* **Success Green Badge & Banner**:
  * Light Background: `#ECFDF5`
  * Badge Circle: `#10B981` / `#16A34A`
  * Title & Subtext: `#065F46` / `#047857`
* **Undo Delete Lavender Banner**:
  * Light Background: `#F3F0FF`
  * Badge Circle & Button: `#6C5CE7`
  * Title & Subtext: `#1E1B4B` / `#6B7280`
* **Error Red Banner**:
  * Light Background: `#FDF2F2`
  * Badge Circle: `#DC2626`
  * Title & Subtext: `#991B1B` / `#B91C1C`
* **Financial Paid Off / Active Badges**:
  * Closed Badge: `Color(0xFFE8F5E9)` background, `Color(0xFF2E7D32)` text.
* **Donut Chart Breakdown**:
  * Principal Cost: `Color(0xFF2979FF)` (Vibrant Royal Blue)
  * Total Interest Cost: `Color(0xFFFF9100)` (Vibrant Amber/Orange)

---

## 4. Navigation & Floating Capsule Shell

### Structure (`lib/Screens/main_shell.dart`)
PayWise uses a custom floating capsule navigation shell elevated above the body.
* **Capsule Styling**:
  * Height: `68px`
  * Margin: `EdgeInsets.symmetric(horizontal: 16, vertical: 10)`
  * Border Radius: `BorderRadius.circular(36)`
  * Shadow: `BoxShadow(blurRadius: 16, offset: Offset(0, 4))`
* **4 Floating Tabs**:
  1. **Home** (`Icons.home_rounded` / `Icons.home_outlined`) $\rightarrow$ `DashboardScreen`
  2. **Simulate** (`Icons.calculate_rounded` / `Icons.calculate_outlined`) $\rightarrow$ `SimulationScreen`
  3. **Info** (`Icons.info_rounded` / `Icons.info_outline`) $\rightarrow$ `InfoScreen`
  4. **Settings** (`Icons.settings_rounded` / `Icons.settings_outlined`) $\rightarrow$ `ProfileScreen`

---

## 5. Animation System & Recent UI Enhancements

### 1. Animated Startup Splash Screen (`splash_screen.dart`)
* **Elastic Logo Entrance**: PayWise logo scales in with an `elasticOut` curve and subtle rotation twist.
* **Shimmer Ring**: Continuous rotating gradient ring surrounding logo.
* **Staggered Title Appearance**: Letter-by-letter animated sequence for "PayWise".
* **Cross-Fade Transition**: 500ms smooth transition to Auth flow/MainShell.

### 2. Global Page Route Transitions (`main.dart`)
* All routes use `SmoothPageTransitionsBuilder` applying an `easeOutCubic` curve with horizontal slide (`Offset(0.06, 0.0)`) and fade (`0.0` to `1.0`).

### 3. Background Privacy Protection Overlay (`main_shell.dart`)
* Automatically displays a **"PayWise Security Protected"** privacy screen whenever app enters background (`inactive` / `paused`).
* Features top gradient shield with `₹` and checkmark, animated background floating particles, 3D center shield, and security description subtext.

### 4. Floating Toast System with 8-Second Undo (`undo_toast.dart`)
* **Global Root Overlay**: Uses `navigatorKey.currentContext` with `rootOverlay: true` to float `90px` above bottom navigation bar.
* **Undo Delete Toast**: 8-second countdown timer. Deleting a loan stages soft-deletion locally; if `Undo` is clicked within 8s, loan is restored instantly. If 8s expire, permanent deletion from Firestore executes.
* **Saved Successfully Toast**: Slide-up green pill notification banner for successful loan creation.

---

## 6. Financial Engines & Simulation Logic

### 1. Equated Monthly Instalment (EMI) Formula
$$\text{EMI} = \frac{P \times r \times (1+r)^n}{(1+r)^n - 1}$$
* $P$ = Principal Loan Amount
* $r$ = Monthly Interest Rate ($\text{Annual Rate} \div 12 \div 100$)
* $n$ = Loan Tenure in Months

### 2. Multi-Mode Lump Sum Simulator
* **Yearly Bonus Mode**: Configure an annual bonus prepayment amount (e.g. ₹50,000) and bonus month (e.g. Month 5) to simulate recurring prepayments across tenure.
* **Custom Multi Mode**: Add dynamic list of custom lump sum payments for any month (e.g. Month 5: ₹50,000, Month 17: ₹50,000, Month 29: ₹50,000).
* **One-Time Mode**: Single prepayment simulation.

---

## 7. App Launcher Icons Setup

* **Mathematical Dead-Center Alignment**: Bounding box of `assets/images/paywise_logo.png` scaled and aligned to exact **Alpha Center of Mass `(511.6, 510.8)`** inside `1024x1024` canvas.
* **Android & iOS Builds**:
  * Android adaptive icons (`mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`, `ic_launcher.xml`).
  * iOS Xcode asset catalog (`AppIcon.appiconset`).

---

## 8. Screen-by-Screen Typography, Text Size & Color Details

Below is the **exhaustive page-by-page specification table** covering typography, font weights, font sizes, color tokens, and layout parameters across every screen in PayWise.

| Screen Name | UI Component / Element | Font Family | Font Size | Font Weight | Color Token / Hex | Layout & Style Parameters |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Splash Screen** | App Logo Title | System / SF Pro / Roboto | `38pt` | `w800` (ExtraBold) | Light: `#1E1B4B`<br>Dark: `#FFFFFF` | Elastic scale entrance, letter spacing `-0.5px` |
| | Subtitle Text | System / SF Pro / Roboto | `14pt` | `w500` (Medium) | Light: `#64748B`<br>Dark: `#94A3B8` | Staggered fade in |
| **Login Screen** | Header Welcome | System / SF Pro / Roboto | `28pt` | `w800` (ExtraBold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Padding `EdgeInsets.symmetric(horizontal: 20)` |
| | Input Field Text | System / SF Pro / Roboto | `14.5pt` | `w600` (SemiBold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Input fill `#FAFAFE`, border `#E2E8F0`, radius `14px` |
| | Login Button | System / SF Pro / Roboto | `16pt` | `w700` (Bold) | `#FFFFFF` | Gradient `[#2A36B1, #3B4CCA]`, radius `16px`, height `54px` |
| **Register Screen** | Screen Title | System / SF Pro / Roboto | `28pt` | `w800` (ExtraBold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Padding `20px` |
| | Form Labels | System / SF Pro / Roboto | `14pt` | `w700` (Bold) | Light: `#0F172A`<br>Dark: `#E2E8F0` | Margin bottom `8px` |
| **Dashboard Screen** | Welcome User Header | System / SF Pro / Roboto | `20pt` | `w800` (ExtraBold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Margin bottom `4px` |
| | Hero Outstanding Card | System / SF Pro / Roboto | `32pt` | `w800` (ExtraBold) | `#FFFFFF` | Gradient `[#1E3C72, #2A5298]`, radius `24px`, shadow `blur 15px` |
| | Outstanding Label | System / SF Pro / Roboto | `13pt` | `w500` (Medium) | `Colors.white70` | Letter spacing `0.2px` |
| | Dynamic Trend Badge | System / SF Pro / Roboto | `12pt` | `w700` (Bold) | Mint Green: `#2E7D32`<br>Red: `#E53935` | Capsule container with `alpha: 0.2` background |
| | Donut Center Cost Text | System / SF Pro / Roboto | `22pt` | `w800` (ExtraBold) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Vector donout chart centered badge |
| | Loan Item Title | System / SF Pro / Roboto | `16pt` | `w700` (Bold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Card surface `#FFFFFF` / `#1E1E1E`, radius `20px` |
| | Loan Item Lender | System / SF Pro / Roboto | `12pt` | `w500` (Medium) | Light: `#64748B`<br>Dark: `#A0A7C2` | Category icon container `#EEF2FF` |
| **Add Loan Screen** | Screen Title | System / SF Pro / Roboto | `26pt` | `w800` (ExtraBold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Top row with 44px circular back button & 3D wallet graphic |
| | Form Field Labels | System / SF Pro / Roboto | `14pt` | `w700` (Bold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Margin bottom `8px` |
| | Input Text & Hints | System / SF Pro / Roboto | `14.5pt` | `w600` (SemiBold) | Text: `#0F172A`<br>Hint: `#94A3B8` | Soft indigo prefix box `#EEF2FF`, radius `14px` |
| | Info Note Box Text | System / SF Pro / Roboto | `12.5pt` | `w500` (Medium) | Light: `#475569`<br>Dark: `#C0C7E5` | Soft periwinkle container `#F1F3FF`, radius `14px` |
| | Save Loan Button | System / SF Pro / Roboto | `15.5pt` | `w700` (Bold) | `#FFFFFF` | Gradient `[#2A36B1, #3B4CCA]`, height `54px`, shadow `blur 16px` |
| | Bottom Footer Badge | System / SF Pro / Roboto | `13pt` | `w700` (Bold) | Text: `#64748B`<br>Brand: `#2A36B1` | Shield verification badge centered below card |
| **Simulation Screen** | TabBar Headers | System / SF Pro / Roboto | `14.5pt` | `w700` (Bold) | Active: `#1E3C72`<br>Inactive: `#64748B` | 3 Tabs (Extra EMI, Lump Sum, Refinancing) |
| | Loan Selector Card | System / SF Pro / Roboto | `15pt` | `w700` (Bold) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Rounded card `#EEF0FD`, opens Modal Bottom Sheet |
| | Sliders & Values | System / SF Pro / Roboto | `16pt` | `w800` (ExtraBold) | `#1E3C72` | Real-time calculation state updates |
| | Insight Banners Text | System / SF Pro / Roboto | `14pt` | `w700` (Bold) | `#1E3C72` / `#2E7D32` | Soft background container, radius `16px` |
| **Loan Details Screen**| Balance Text | System / SF Pro / Roboto | `30pt` | `w800` (ExtraBold) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Outstanding balance overview card |
| | Amortization Header | System / SF Pro / Roboto | `16pt` | `w700` (Bold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | PDF export & history actions |
| **Info / Glossary Screen**| Hero Banner Title | System / SF Pro / Roboto | `24pt` | `w800` (ExtraBold) | `#FFFFFF` | Indigo gradient card `[#1E3C72, #2A5298]` |
| | Terminology Items | System / SF Pro / Roboto | `15pt` | `w700` (Bold) | Light: `#1E3C72`<br>Dark: `#90B3E8` | Expandable glossary cards |
| **Profile & Settings**| Username Header | System / SF Pro / Roboto | `22pt` | `w800` (ExtraBold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Top curved navy gradient header `[#1E3C72, #2A5298]` |
| | Setting Tile Title | System / SF Pro / Roboto | `15pt` | `w700` (Bold) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Leading icon box `#EBF1F9`, icon `#1E3C72` |
| | Setting Tile Subtitle| System / SF Pro / Roboto | `12pt` | `w400` (Regular) | `#64748B` | Switch active track color `#1E3C72` |
| | Help Center Card | System / SF Pro / Roboto | `15pt` | `w700` (Bold) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Soft navy container `#EBF1F9`, border `#1E3C72` |
| **Toast Notifications**| Undo Toast Title | System / SF Pro / Roboto | `14.5pt` | `w700` (Bold) | Light: `#1E1B4B`<br>Dark: `#FFFFFF` | Lavender container `#F3F0FF`, purple badge `#6C5CE7` |
| | Undo Toast Subtitle | System / SF Pro / Roboto | `12.5pt` | `w500` (Medium) | Light: `#6B7280`<br>Dark: `#A5B4FC` | 8-second countdown timer |
| | Success Toast Title | System / SF Pro / Roboto | `14.5pt` | `w700` (Bold) | Light: `#065F46`<br>Dark: `#FFFFFF` | Emerald container `#ECFDF5`, green badge `#10B981` |
| | Error Toast Title | System / SF Pro / Roboto | `14.5pt` | `w700` (Bold) | Light: `#991B1B`<br>Dark: `#FECDD3` | Red container `#FDF2F2`, red badge `#DC2626` |

---

## 9. Security & Authentication Architecture

1. **Authentication Flow (`AuthWrapper`)**: Listens to `FirebaseAuth.instance.authStateChanges()`. Unauthenticated users are routed to `LoginScreen` / `RegisterScreen`.
2. **Google Sign-In Account Chooser & Navigation**:
   - `signInWithGoogle()` in `AuthService` executes `await googleSignIn.signOut()` prior to launching `googleSignIn.signIn()`. This clears cached credentials and forces Google Play Services to always display the **Google Account Chooser Modal** showing all emails on the device.
   - `LoginScreen` explicitly calls `Navigator.pushReplacementNamed(context, '/dashboard')` upon successful Google authentication, routing the user straight to the dashboard.
3. **Biometric Security**: Integrated with `local_auth`. When biometric lock is enabled in `SettingsProvider`, `AuthWrapper` requires fingerprint/FaceID authentication before presenting the dashboard.
4. **Password Management**: Fully functional password visibility toggles (`_obscurePassword`) on Login/Register screens and active Firebase password reset email dispatchers.
5. **Smart Dual-Provider Account Deletion Security Modal (`DeleteAccountScreen`)**:
   - **Google Sign-In Users**: Presents a dedicated **Google Identity Verification Modal** (`reauthenticateWithGoogle()`) utilizing Google Play Services OAuth credentials.
   - **Email / Password Users**: Presents a secure **Account Password Modal** (`reauthenticateWithPassword()`) requiring account password entry before proceeding.
   - **7-Day Grace Period Scheduling**: Schedules `deletionScheduled: true` and `scheduledDeletionDate: Timestamp` (7 days out) in Firestore `users/$userId`. Logs out the user and retains their identity/data safely during the 7-day window.
   - **1-Tap Recovery Upon Login**: If the user logs back in within 7 days, `AuthWrapper` detects the active deletion schedule and presents a **"Restore Scheduled Account?"** modal. Tapping **"Restore Account"** cancels deletion (`deletionScheduled: false`) and restores access instantly.
   - **Auto Data Purge After 7 Days**: If 7 days pass without login recovery, the account is automatically purged (all loans, transaction sub-collections, user Firestore document, and `FirebaseAuth` account).
   - **Instant Immediate Deletion Option**: Users can also choose **"Delete Permanently Now"** to immediately erase all data and delete their account without waiting 7 days.
6. **Loan Deletion Persistence & Immediate Firestore Sync (`LoanProvider`)**:
   - Deleting a loan stages `_stagedForDeletionIds` and executes an immediate Firestore document purge while filtering the Firestore `.snapshots()` stream, guaranteeing that app refresh or restart never restores deleted loans.
 7. **RBI & Indian Bank Maximum Tenure Limits & 50% Interest Rate Cap (`AddLoanScreen`)**:
    - Enforces RBI / banking tenure limits per loan category (Home: 360m, LAP/Business: 240m, Education: 180m, Car: 96m, Personal: 84m, Two-Wheeler: 60m, Gold: 36m) with dynamic max tags, a 50% maximum interest rate cap, live red error banners, and strict all-field form validation that locks the Save button until valid.
 8. **Persistent Bank Autocomplete (`AddLoanScreen`)**:
    - Uses a persistent `_lenderFocusNode` and inline suggestion card (`_buildLenderBankSuggestions`) to deliver smooth search and selection across 33 Public & Private Sector Banks without losing keyboard focus.
 9. **Crash-Proof Toast System (`UndoToastManager`)**:
    - Accesses `navigatorKey.currentState.overlay` directly to present root overlay toasts safely without triggering `No Overlay widget found` exceptions.
 10. **Retroactive & Single Payment Per Day Engine (`LoanDetailsScreen` & `LoanProvider`)**:
    - Features a custom payment date picker in the Record Payment popup modal for retroactive/forgotten payments, restricted strictly to today or past dates (`lastDate: DateTime.now()`).
    - Enforces a 1-payment-per-day restriction per loan in `LoanProvider.recordPayment()` to prevent duplicate payments on the same date.
 11. **5 Smart EMI Due Notification System (`NotificationService`)**:
    - Automatically schedules 5 dedicated push notification reminders (3-days before, 1-day before last date, due today, 1-week ahead dynamic weekday, and overdue alert).
    - Requests native Android OS `POST_NOTIFICATIONS` runtime permissions automatically.

---

## 10. Release Build & Distribution Specifications

PayWise is compiled into standalone, optimized production release binaries:

| Architecture Target | APK File Path | Size | Description |
| :--- | :--- | :--- | :--- |
| **ARM 64-bit (arm64-v8a)** | [app-arm64-v8a-release.apk](file:///C:/Users/pipal/OneDrive/Desktop/Paywise/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk) | **40.5 MB** | Primary architecture for 99% of modern Android smartphones |
| **ARM 32-bit (armeabi-v7a)** | [app-armeabi-v7a-release.apk](file:///C:/Users/pipal/OneDrive/Desktop/Paywise/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk) | **38.2 MB** | Legacy Android devices |
| **x86 64-bit (x86_64)** | [app-x86_64-release.apk](file:///C:/Users/pipal/OneDrive/Desktop/Paywise/build/app/outputs/flutter-apk/app-x86_64-release.apk) | **41.9 MB** | Android Emulators & Chromebooks |

---

## 11. Developer Guidelines & Summary

When working with or extending the **PayWise** codebase:
* Maintain the **Deep Navy & Royal Blue** design system (`#1E3C72` / `#2A5298` gradients with `#EEF2FF` / `#EBF1F9` soft accents).
* Keep all top AppBars transparent (`backgroundColor: Colors.transparent`, `elevation: 0`) and wrap main view bodies in `SafeArea(bottom: false)` to prevent status bar bleed.
* Maintain dynamic scroll padding (`SizedBox(height: 120)` at bottom of scrollable views) so content is never obscured by the 68px floating capsule navigation bar or bottom toast notifications.
* Use `LoanProvider` for all financial data mutations, staging soft-deletions, and Firestore synchronization.
* Use `UndoToastManager.showUndoDeleteToast` for deletion actions and `UndoToastManager.showSuccessToast` for successful form saves.
