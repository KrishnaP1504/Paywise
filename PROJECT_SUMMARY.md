# Project Summary: PayWise

---

## 1. Project Name & Purpose

**Name:** PayWise — Smart Loan & Debt Tracker
**Purpose:** A production-ready, cross-platform Flutter application designed to help borrowers track multiple active loans, visualize debt amortization, calculate interest savings through extra prepayments, and receive smart local payment due notifications.

---

## 2. Tech Stack

- **Language(s):** Dart 3.x
- **Framework(s):** Flutter (Android, iOS, Web ready)
- **Backend/DB:** Firebase Authentication (Email/Password & Google Sign-In), Cloud Firestore, Firebase Realtime Database
- **State Management:** Provider (`provider`)
- **Key Packages:**
  - `fl_chart` (Interactive financial charts)
  - `table_calendar` (Monthly EMI due date calendar)
  - `flutter_local_notifications` (5-tier local push reminders)
  - `flutter_secure_storage` & `local_auth` (Biometric security)
  - `pdf` & `printing` (Amortization schedule export)
  - `intl` (Currency & date formatting)

---

## 3. Current Status

**✅ Done and working:**
- **Authentication & Security:** Firebase Auth with Email/Password & Google Sign-In (with Web Client ID fallback).
- **Financial Dashboard:** Real-time summary cards, monthly outflow calculation, and principal vs. interest pie chart.
- **Loan Ledger System:** Add loan, record regular EMI or extra payments, automatically recalculate principal balance and interest saved.
- **Monthly EMI Calendar:** Visual calendar highlighting due dates (Red) and paid dates (Green).
- **Savings & Prepayment Simulator:** Interactive slider tool calculating exact time & interest saved by paying extra monthly or applying annual bonuses.
- **Amortization PDF Export:** One-tap PDF generation and download.
- **Smart Notification Engine:** 5-tier local notification system (3-Days Before, 1-Day Before, Due Today, Next Weekday Ahead, and Overdue Alert).
- **Biometric App Lock:** Hardware-backed biometric security toggle.
- **Account & Data Purge:** Complete in-app account deletion flow purging all user records from Firestore and Firebase Auth.
- **Production Hardening:** Cloud Firestore & Realtime Database security rules, environment variable isolation (`EnvConfig`), release debug log suppression (`kReleaseMode`), and responsive UI layouts tested on Samsung A35 (6.6") and 20+ screen resolutions.

**🚧 In progress / partially working:**
- None (App is 100% feature-complete and pushed to GitHub repository).

**❌ Not started / broken:**
- None.

---

## 4. Structure / Architecture

```
Paywise/
├── android/                   # Native Android configuration & Manifests
├── ios/                       # Native iOS configuration
├── lib/
│   ├── config/
│   │   └── env_config.dart    # Environment configuration & Dart-define setup
│   ├── models/
│   │   ├── loan_model.dart    # Loan data schema & amortization calculations
│   │   └── transaction_model.dart # Payment transaction schema
│   ├── providers/
│   │   ├── loan_provider.dart # Main financial state & Firestore listener
│   │   └── settings_provider.dart # Theme & biometric preferences state
│   ├── Screens/
│   │   ├── add_loan_screen.dart       # New loan entry screen
│   │   ├── calendar_screen.dart       # EMI due calendar planner
│   │   ├── compare_screen.dart        # Loan comparison tool
│   │   ├── dashboard_screen.dart      # Main financial overview & FAB
│   │   ├── delete_account_screen.dart # Data purge screen
│   │   ├── info_screen.dart           # Loan terminology & educational guides
│   │   ├── loan_details_screen.dart   # Loan history & record payment modal
│   │   ├── login_screen.dart          # User login
│   │   ├── main_shell.dart            # Root shell with floating navigation bar
│   │   ├── prepayment_screen.dart     # Extra payment calculator
│   │   ├── profile_screen.dart        # User profile & biometric settings
│   │   ├── register_screen.dart       # User registration
│   │   ├── savings_screen.dart        # Total savings summary
│   │   ├── simulation_screen.dart     # Savings simulator (Extra EMI/Lump sum)
│   │   └── splash_screen.dart         # Startup splash screen
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Auth & Google Sign-In
│   │   ├── notification_service.dart  # Local notification scheduler
│   │   ├── pdf_service.dart           # Amortization PDF generator
│   │   └── secure_storage_service.dart # Biometric key storage
│   ├── widgets/
│   │   └── undo_toast.dart            # Custom toast notifications
│   ├── firebase_options.dart          # Firebase project options
│   └── main.dart                      # App entry point & log muting
├── .env.example                       # Environment template
├── .gitignore                         # Strict exclusion for keys & secrets
├── database.rules.json                # Firebase Realtime Database Security Rules
├── firestore.rules                   # Production Cloud Firestore Security Rules
├── README.md                          # Repository documentation
└── pubspec.yaml                       # Project dependencies
```

---

## 5. Key Decisions & Constraints

- **Provider Architecture:** Used `Provider` for lightweight, predictable reactive state management across all screens.
- **Environment Isolation:** Used `EnvConfig` with `String.fromEnvironment` (`--dart-define`) to ensure no sensitive credentials exist as hardcoded string literals.
- **Default Deny Security Rules:** Applied strict UID ownership checks in Cloud Firestore and Realtime Database rules (`request.auth.uid == userId`).
- **100% Local Notifications:** Utilized `flutter_local_notifications` for offline payment reminders without reliance on external notification servers.
- **Responsive Layout Design:** Applied dynamic bottom scroll insets (`150px`) and `84px` FAB padding to guarantee clean UI layouts across Android 3-button navigation, gesture bars, and all screen sizes.

---

## 6. Known Issues / Blockers

- **None:** All previous issues (Google Sign-In `ApiException: 10`, secret scanning alerts, FAB alignment bugs, and README rendering) have been fully resolved and verified.

---

## 7. What I need help with right now

- Complete project documentation generated! Ready for future feature enhancements or Google Play Store release submission.