# PayWise - Complete Application Guide & System Walkthrough

---

## 1. Executive Overview & Value Proposition

### What is PayWise?
PayWise is an intelligent, privacy-first personal debt management, loan tracking, and repayment optimization application. Designed for borrowers managing personal loans, home mortgages, vehicle financing, education loans, or credit card debt, PayWise empowers users to take command of their liabilities, uncover hidden interest costs, and eliminate debt years ahead of schedule.

### What Real-World Problems Does PayWise Solve?
1. **The Compounding Interest Trap**: Financial institutions design loans so that the majority of early EMI payments go toward interest rather than principal. Most borrowers never realize that paying even a small extra amount early can cut years off their loan and save lakhs or thousands in interest.
2. **Scattered Loan Visibility**: Borrowers often have debts across multiple banks, credit card providers, and non-banking financial companies (NBFCs). Without a unified command center, tracking payment due dates, remaining balances, and total monthly outflows is stressful and prone to missed payments.
3. **Black-Box Amortization**: Traditional banking statements are complex, static, and difficult to decipher. PayWise decodes every loan into an interactive, transparent amortization timeline.
4. **Guesswork in Prepayment & Refinancing**: Borrowers often wonder: *"What happens if I pay an extra ₹2,000 every month?"*, *"What if I put my annual festival bonus of ₹50,000 toward my home loan?"*, or *"Is it worth paying a 1% balance transfer fee to switch my loan to another bank at a 0.75% lower interest rate?"* PayWise replaces guesswork with real-time financial simulation.

### Why Should You Use PayWise?
- **Total Clarity**: View your entire debt portfolio in one unified dashboard.
- **Actionable Savings**: Discover exact strategies to save money and become debt-free faster.
- **Smart Reminders**: Never incur late payment penalties or damage your credit score.
- **Complete Privacy**: No bank account scrapers, no SMS snooping, and no selling of your financial profile to loan brokers.

---

## 2. User Data, Security, Privacy & Compliance Policy

### Privacy-First Architecture
PayWise is engineered with a strict zero-exploitation philosophy:
- **No Third-Party Advertising**: PayWise contains zero advertising networks, tracking pixels, or data brokers.
- **No Financial Data Harvesting**: Your loan entries, amounts, and lenders are never aggregated, monetized, or shared with lenders.
- **No SMS or Bank Scraping**: Unlike traditional expense tracking apps that read your private SMS messages and scrape bank credentials, PayWise works purely on the loans and payments you deliberately manage.

### Hardware-Backed Biometric Security
- **Secure Enclave Protection**: When you enable Biometric Login (Face ID, Touch ID, or Android Fingerprint), the credential state is stored in the device's hardware-backed Keystore (Android) or Keychain (iOS).
- **Fail-Closed Security Model**: If biometric authentication fails or is cancelled, access to financial data is denied. The app will never default to an unlocked state upon error.
- **Background Privacy Curtain**: When you switch away from PayWise to another app or the home screen, PayWise immediately applies a dark privacy blur overlay over the entire screen, preventing shoulder-surfing and blocking sensitive financial figures from appearing in the operating system's app switcher preview.

### Data Storage & Isolation
- **Per-User Sandboxed Storage**: Every user's data is stored in an isolated document path in Cloud Firestore under their unique Firebase Authentication ID. No user can read or modify another user's loan documents.
- **Offline Disk Persistence**: PayWise maintains an encrypted local cache on your device. You can open the app on a flight, in rural areas, or with no cellular data, and view your loans and amortization schedules instantly. Any changes made offline automatically synchronize once network connectivity resumes.

### Account Deletion with 7-Day Safety Net
- **Accidental Deletion Protection**: Deleting an account full of historical loan records can be catastrophic if done by mistake or in frustration. PayWise introduces a 7-day grace period for account deletion.
- **Instant Restoration**: If you change your mind within 7 days, logging back in presents an immediate "Restore Account" option that cancels deletion with a single tap.
- **Permanent Purge**: If 7 days elapse without cancellation, PayWise automatically and irreversibly purges the user profile, all associated loan documents, all payment history, and the authentication account permanently.

---

## 3. Cloud & Firebase Integration Architecture

PayWise combines local device efficiency with Google Cloud infrastructure via Firebase:

| Component | How PayWise Uses It | Benefit to User |
|---|---|---|
| **Firebase Authentication** | Secure sign-in via Email/Password and Google Sign-In with OAuth token validation. | One-tap access across devices without remembering separate database credentials. |
| **Cloud Firestore** | Cloud database storing user profiles, loan records, and payment logs. | Instant real-time multi-device sync; changes made on your tablet appear on your phone immediately. |
| **Offline Disk Persistence** | Firestore local persistence engine enabled with unlimited cache size. | Instant app startup; no loading spinners when opening the app with slow internet. |
| **Native iOS Configuration** | Registered inside Xcode project bundle resources (`GoogleService-Info.plist`). | Full compatibility with iOS security standards, push notification services, and Apple guidelines. |
| **Native Android Configuration** | Google Services Gradle plugin configuration (`google-services.json`). | Native Android integration without runtime configuration overhead. |

---

## 4. Theme & Visual Design System

### Design Philosophy
PayWise is crafted around a modern, elevated glassmorphism visual language. Translucent frosted glass containers, subtle multi-layered drop shadows, and high-contrast typography give the application a premium, polished aesthetic while ensuring data readability remains paramount.

### Curated Color Palette

| Color Name | Hex Code | Semantic Role & Where It Is Used |
|---|---|---|
| **Deep Navy Blue** | `#1E3C72` to `#2A5298` | Primary brand color; used for top app bar accents, hero cards, primary action buttons, and active tabs. |
| **Vibrant Indigo** | `#4F46E5` to `#6366F1` | Tech-forward secondary accent; used for interactive icons, sliders, focus borders, and badges. |
| **Success Emerald** | `#10B981` / `#2E7D32` | Positive financial health; used for principal paid progress, interest saved figures, and paid-off badges. |
| **Amber Gold** | `#F59E0B` / `#D97706` | Cost and attention indicators; used for interest burden portions, upcoming payment notices, and night mode icons. |
| **Urgent Crimson** | `#EF4444` / `#DC2626` | Liability alerts; used for overdue payments, loan deletion actions, and error messages. |
| **Light Canvas** | `#F8F9FA` | Light mode background; crisp, glare-free off-white surface for comfortable daytime viewing. |
| **Dark Obsidian** | `#121212` & `#1B1D30` | Dark mode background; deep OLED-friendly surfaces with elevated `#1E1E1E` glass cards to prevent eye strain. |

### Dynamic Theme Adaptation (Phone System Sync + Manual Override)
- **Automatic First Launch Detection**: On first launch and by default, PayWise automatically detects whether your operating system (iOS or Android) is set to Dark Mode or Light Mode.
- **Real-Time System Tracking**: If your phone is set to automatically shift to Dark Mode at sunset, PayWise smoothly transitions alongside your phone without requiring manual intervention.
- **Manual Preference Override**: If you prefer Dark Mode during the daytime (or Light Mode at night), flipping the switch in Settings saves your preference permanently.
- **One-Tap "Auto" Reset**: Whenever you have a custom theme selected, an intuitive "Auto" button appears in Settings so you can revert back to following your phone's system theme whenever you choose.

---

## 5. Notification & Automated Alert Engine

PayWise includes an on-device, timezone-aware background notification system designed to prevent late fees and protect credit scores:

### Notification Triggers
1. **Due Today Reminders**: Triggered at 9:00 AM on the day an EMI payment is due, prompting the user to confirm the deduction.
2. **Due Tomorrow Reminders**: Sent 24 hours before a payment date, giving the user an advance heads-up to ensure sufficient bank balance.
3. **Advance Reminders**: Configurable notice days in advance for large payments like home loan installments.
4. **Overdue Escalation Alerts**: Sent if an EMI date has passed without being marked as paid, preventing multi-day lapses.

### User Control
Every notification category can be individually toggled in the Settings screen, alongside a master switch that silences all alerts when desired.

---

## 6. Comprehensive Screen-by-Screen Walkthrough

### 1. Splash & Launch Screen
- **Visual Presentation**: High-resolution centered PayWise emblem enveloped in a rotating shimmer ring, floating ambient particles, smooth sliding "Pay" and "Wise" typography, and an inspiring tagline: *"Smart Loans, Smarter You"*.
- **Background Execution**: While the 1.1-second entrance animation plays, the app pre-initializes Firebase, registers local notifications, verifies encrypted biometric keys, and queries local cached loans.
- **Transition**: Smoothly cross-fades into the authentication gatekeeper without any abrupt visual jumps.

### 2. Welcome & Onboarding Screen
- **Target Audience**: First-time users or users who have logged out.
- **Visuals**: Clean welcoming hero illustration, value proposition cards highlighting debt reduction, interest savings, and privacy guarantees.
- **Actions**: Direct buttons to either Log In with an existing account or Create a New Account.

### 3. Authentication Suite
- **Login Screen**:
  * Clean form inputs with floating labels for Email and Password.
  * Password visibility toggle eye icon.
  * One-tap Google Sign-In with automated OAuth authentication.
  * "Forgot Password?" dialog that sends a secure password reset link directly from Firebase.
  * Input validation with clear inline error messages (e.g., malformed email, empty password).
- **Register Screen**:
  * Full Name, Email, Password, and Password Confirmation fields.
  * Immediate real-time account creation in Firebase Auth.
  * Initializes a corresponding Firestore user profile document with default settings.
- **Session Guardian (AuthWrapper)**:
  * Manages app state: verifies if the user is authenticated, checks if biometric lock is active, and intercepts unauthorized access.

### 4. Main Application Shell & Navigation
- **Navigation Style**: Bottom navigation bar styled with translucent frosted glass, vibrant active icon glows, and haptic feedback.
- **Four Core Destinations**:
  1. **Dashboard (Home)**: Portfolio summary, active loans, quick payments, and visual breakdown.
  2. **Simulator**: Interactive playground for prepayment, extra EMI, and refinancing calculations.
  3. **Learn (Info)**: Financial literacy handbook and glossary.
  4. **Profile (Settings)**: User details, theme customization, security toggles, and notification settings.
- **Global Floating Action Button (FAB)**: Prominent elevated button for instantly adding a new loan from anywhere in the app.

### 5. Dashboard Screen (The Financial Command Center)
- **Top Summary Card**:
  * Displays total outstanding debt across all active loans in large, formatted currency.
  * Shows total monthly commitment (sum of all EMIs due this month).
  * Circular progress ring illustrating overall portfolio payoff percentage.
- **Category Filter Tabs**:
  * Filter visible loans by category (All, Home, Vehicle, Personal, Education, Credit Card, Gold, Business).
- **Active Loan Cards**:
  * Card shows loan title, lender name, remaining balance, interest rate, and next EMI due date.
  * Visual progress bar showing exact percentage of principal paid vs. remaining.
- **Swipe Actions on Cards**:
  * **Swipe Right**: Instantly records one scheduled EMI payment, updates the loan balance, logs the transaction, and recalculates future amortization.
  * **Swipe Left**: Prompts confirmation to archive or delete the loan, with an instant "Undo" toast in case of accidental swipes.
- **Portfolio Distribution Chart**:
  * Interactive donut/pie chart showing how your total liabilities are split across categories or lenders.
- **Celebration Banner**:
  * When all active loans are paid off, the dashboard displays a celebratory graphic congratulating the user on becoming debt-free.

### 6. Add Loan Screen
- **Core Input Fields**:
  * **Loan Title**: e.g., "Home Loan - SBI", "Honda City Car Loan".
  * **Lender / Bank Name**: Name of the lending institution.
  * **Principal Amount**: Total borrowed sum (formatted with Indian or International currency groupings).
  * **Interest Rate (%)**: Annual percentage rate.
  * **Tenure**: Duration in Months or Years, with automatic conversion.
  * **Loan Start Date**: Interactive calendar picker to select when the loan originated.
- **Category Picker**:
  * Selectable category chips with dedicated iconography (Home, Auto, Education, Personal, Business, Credit Card, Medical, Gold).
- **Interest Type Model**:
  * Reducing Balance (Standard for bank loans) vs. Flat Rate (common for private/dealer financing).
- **Live Calculation Preview**:
  * As you adjust numbers, a live preview card at the bottom continuously recalculates and displays the exact Monthly EMI, Total Interest Payable, and Total Repayment Amount before saving.

### 7. Loan Details & Amortization Screen
- **Loan Snapshot**:
  * Complete breakdown: Original Principal, Current Remaining Balance, Total Interest, Tenure Elapsed vs. Remaining, and Next Due Date.
- **Interactive Amortization Table**:
  * Month-by-month financial ledger showing:
    * Payment Month & Year.
    * EMI Amount.
    * Principal component (money that actually reduces your debt).
    * Interest component (money paid to the bank as profit).
    * Closing balance after that month's payment.
- **Payment History Ledger**:
  * Complete audit trail of every payment recorded for this loan, including date, amount, and payment type (Scheduled EMI vs. Lump Sum Prepayment).
- **Prepayment Action Button**:
  * Opens a quick dialog to record an ad-hoc extra payment, immediately showing how many months it shaves off the loan.
- **Statement & PDF Generation**:
  * Generates an official, print-ready PDF Amortization Statement with custom headers, lender details, and full payment schedules.
  * Integrated with system printing and sharing (AirPrint on iOS, Android Print Spooler, WhatsApp, Email, or Files export).

### 8. Loan Simulator Screen (The Prepayment & Savings Engine)
The simulator is divided into three specialized tabs:

#### Tab A: Extra EMI Simulator
- **Concept**: *"What happens if I increase my monthly payment by a set amount every month?"*
- **Controls**: Interactive slider and custom amount field allowing you to specify an extra monthly sum (e.g., an extra ₹3,000/month).
- **Instant Output Metrics**:
  * **Interest Saved**: Exact currency amount saved over the life of the loan.
  * **Tenure Reduced**: Months and years shaved off your repayment timeline.
  * **New Payoff Date**: Visual calendar comparison showing your original payoff date vs. your accelerated freedom date.

#### Tab B: Lump Sum Prepayment Simulator
- **Concept**: *"What happens if I pay a one-time lump sum (from a bonus, tax refund, or savings) or periodic annual payments?"*
- **Modes**:
  1. **Single Lump Sum**: Select an amount and choose which month to apply it.
  2. **Annual Recurring Prepayment**: Simulates paying a bonus every year in a specific month (e.g., Diwali or New Year bonus).
  3. **Custom Prepayment Schedule**: Add multiple arbitrary lump sums across different months.
- **Instant Output Metrics**:
  * Calculates the exact interest reduction and tenure reduction for every combination.

#### Tab C: Refinancing & Balance Transfer Simulator
- **Concept**: *"Another bank is offering me a lower interest rate. Is it worth switching after paying processing fees?"*
- **Controls**:
  * Input New Offered Interest Rate (%).
  * Input Processing Fee / Transfer Charges (flat fee or percentage of balance).
- **Instant Output Metrics**:
  * **New Monthly EMI**: Lower monthly installment amount.
  * **Monthly EMI Savings**: How much cash is freed up in your monthly budget.
  * **Net Lifetime Savings**: Total interest saved minus all transfer fees.
  * **Break-Even Point**: Exact number of months until the lower interest offsets the upfront switching fees.

#### Ergonomic Design for iOS & Android
- Built-in `(✓)` Done buttons inside number fields.
- Translucent background tap-to-dismiss gesture support.
- Drag-and-scroll dismissal on all scrollable views, ensuring number keypads never remain stuck on iOS.

### 9. Loan Analysis & Strategy Screen
- **Portfolio Debt-to-Income (DTI) Evaluation**: Compares total monthly loan outflows against income to display debt risk levels.
- **Payoff Strategy Comparison**:
  * **Avalanche Method**: Directs extra payments to the highest-interest loan first to maximize mathematical savings.
  * **Snowball Method**: Directs extra payments to the smallest-balance loan first to build psychological momentum.

### 10. Loan History & Cleared Debt Archive
- **Purpose**: When a loan reaches zero balance, it is celebrated and gracefully transitioned out of the active dashboard into the History Archive.
- **Metrics Displayed**:
  * Total Principal Cleared across your lifetime.
  * Total Interest Saved through early prepayments.
  * Full historical record of completed loans, keeping the main dashboard clean and focused on current liabilities.

### 11. Learn & Financial Literacy (Info) Screen
- **Core Financial Glossary**:
  * Plain-English definitions of complex terms: Principal, Amortization, Reducing Balance, Fixed vs. Floating Rates, Processing Fees, Prepayment Penalties, Foreclosure, Tenure, and Credit Utilization.
- **Strategic Guides**:
  * Step-by-step tactics to negotiate lower interest rates with existing lenders.
  * Dos and Don'ts of balance transfers.
  * How early prepayments impact loans differently than late prepayments.

### 12. Profile & Settings Screen
- **User Information Card**:
  * Displays user profile photo, display name, and authenticated email address.
- **Edit Profile**:
  * Opens sub-screen to update name, phone number, and avatar with instant Firestore synchronization.
- **Appearance (Dark Mode)**:
  * Toggle switch with real-time phone system theme synchronization (`Following phone theme (Dark/Light)`).
  * Manual override capability (`Always Dark` / `Always Light`).
  * "Auto" button to instantly restore OS-level theme following.
- **Security (Biometric Authentication)**:
  * Switch to activate Face ID / Touch ID / Fingerprint lock.
  * Tests biometric hardware compatibility before enabling.
- **Interaction (Swipe Actions)**:
  * Switch to enable or disable swipe-to-pay and swipe-to-delete gestures on dashboard cards.
- **Notification Preferences**:
  * Individual toggles for Due Today, Due Tomorrow, Advance Reminders, and Overdue notices.
- **Danger Zone (Account Deletion)**:
  * Access to the 7-Day Grace Period account deletion workflow.
- **App Version & Copyright**:
  * Official version stamp: `Version 1.0.0`.
  * Copyright attribution: `© 2026 PayWise. All rights reserved.`.

### 13. Edit Profile Screen
- Allows updating personal display name and contact details.
- Validates text inputs and updates Firebase Auth and Firestore user records simultaneously.

### 14. Delete Account Screen
- Displays an honest, transparent breakdown of what account deletion entails.
- Explains the 7-day safety period and outlines how all loans, transactions, and credentials will be irreversibly erased if not cancelled within 7 days.
- Provides a clear button to confirm scheduling deletion or immediately cancel an active deletion request.

---

## 7. Version & Copyright

- **Application Name**: PayWise
- **Current Release Version**: `1.0.0`
- **Build Target**: iOS & Android
- **Copyright**: © 2026 PayWise. All rights reserved.
