# PayWise — Complete Application Guide, Architecture & System Walkthrough

---

## 1. Executive Summary, Mission & Value Proposition

### What is PayWise?
**PayWise** is a modern, privacy-first personal debt management, loan tracking, and repayment optimization platform. Designed for individuals managing personal loans, home mortgages, vehicle financing, education loans, gold loans, or credit card debt, PayWise empowers borrowers to take command of their liabilities, uncover hidden interest costs, and eliminate debt years ahead of schedule.

* **Application Name**: PayWise
* **Package / Namespace**: `com.paywise.app`
* **Release Version**: `1.0.0` (Build `1`)
* **Copyright**: © 2026 PayWise. All rights reserved.
* **Target Platforms**: Android & iOS (Tested on Android API 34/35 & iOS 17+ devices)

### Real-World Problems PayWise Solves
1. **The Compounding Interest Trap**: Banking amortization schedules front-load interest, meaning early EMI payments go overwhelmingly toward bank profit rather than reducing principal. PayWise reveals the exact principal-to-interest breakdown for every payment.
2. **Scattered Debt Blindspots**: Borrowers with loans across multiple banks, credit card issuers, and NBFCs frequently struggle to track aggregate monthly commitments and due dates, leading to late penalties and credit score damage.
3. **Black-Box Amortization**: Traditional static bank statements are cumbersome and difficult to interpret. PayWise transforms static statements into interactive, transparent amortization schedules.
4. **Prepayment & Balance Transfer Guesswork**: Borrowers often question whether paying an extra monthly amount or making a yearly festival lump-sum payment will meaningfully reduce their debt, or whether a balance transfer with switching fees is mathematically worthwhile. PayWise replaces guesswork with real-time financial simulation.

### Why Borrowers Choose PayWise
* **Unified Command Center**: Real-time visibility into total outstanding principal, total interest, and collective monthly EMI outflow.
* **Accelerated Freedom**: Discover exact prepayment milestones to shave years and lakhs of interest off your debt.
* **Late Fee Immunity**: Multi-stage, timezone-aware push notifications guarantee you never miss a payment.
* **Uncompromising Privacy**: Zero advertising trackers, no SMS harvesting, and zero third-party monetization.

---

## 2. User Data, Security, Privacy & Compliance Policy

### Privacy-First Architecture
PayWise adheres to a strict zero-exploitation standard:
* **No Third-Party Advertising**: PayWise contains zero advertising networks, tracking SDKs, or data brokers.
* **No Data Monetization**: Your financial profile, loan amounts, and lender names are never aggregated, sold, or shared.
* **No SMS or Account Scraping**: Unlike traditional expense apps that read your private SMS inbox and scrape bank credentials, PayWise operates strictly on the loan data you deliberately enter.

### Hardware-Backed Biometric Security
* **Secure Enclave Storage**: Biometric authentication state is stored directly within the device's hardware-backed Keystore on Android and Keychain on iOS.
* **Fail-Closed Security Model**: If biometric verification fails, is cancelled, or encounters a sensor error, access to financial data is denied. The app will never default to an unlocked state upon error.
* **Background Privacy Curtain**: The moment PayWise is sent to the background or the operating system app switcher is engaged, the app applies a dark security shield overlay over the interface, preventing shoulder-surfing and blocking financial figures from appearing in app preview screenshots.

### Data Storage, Isolation & Offline Persistence
* **Per-User Document Sandboxing**: Every user's data is isolated in Cloud Firestore under their unique Firebase Authentication ID (`/users/{uid}/loans/`). Users cannot read, query, or modify records belonging to any other user.
* **Offline Disk Persistence**: PayWise maintains an encrypted local disk cache on the device. Users can access loan schedules, review payment histories, and run simulations completely offline. Any offline modifications queue locally and synchronize immediately once connectivity resumes.

### Dual-Provider Account Deletion with 7-Day Safety Net
Accidental account deletion can permanently destroy years of carefully curated financial records. PayWise features a multi-tiered deletion safeguard:
* **Identity Re-Authentication**:
  * **Google Sign-In Users**: Verified via a native Google Identity Verification modal using Google Play Services OAuth credentials.
  * **Email/Password Users**: Verified via a secure Account Password Confirmation modal.
* **7-Day Grace Period**: Scheduling account deletion sets a 7-day timer, logs the user out, and safely preserves data.
* **1-Tap Recovery Upon Login**: If the user logs back in within 7 days, the app detects the pending schedule and offers an instant "Restore Account" button that cancels deletion immediately.
* **Automated Server Purge**: If 7 days elapse without login recovery, the server irreversibly erases the user profile, all associated loan documents, all payment history, and the authentication account permanently.
* **Immediate Deletion Option**: For users requiring instant removal, a "Delete Permanently Now" action executes an immediate, irreversible wipe.

---

## 3. Technology Stack & Cloud Infrastructure

### Core Framework & Architecture
* **Framework**: Flutter (v3.31+)
* **Language**: Dart (v3.0+)
* **UI Architecture**: Material 3 Design System with custom glassmorphism styling and a floating pill navigation shell.
* **State Management**: Provider Pattern using MultiProvider, Selector, and ChangeNotifierProvider for responsive, selective widget rebuilds.

### Cloud & Backend Integration

| Service / Tool | Implementation in PayWise | Operational Benefit |
|---|---|---|
| **Firebase Authentication** | Email/Password credentials and Google Sign-In with OAuth token validation. | Secure, friction-free login across multiple devices. |
| **Cloud Firestore** | Cloud database storing user profiles, loan documents, and payment sub-collections. | Instant real-time multi-device sync and automatic offline write queuing. |
| **Offline Disk Persistence** | Firestore local persistence engine enabled with unlimited cache size. | Instant app launch with zero loading delay, even on offline or spotty connections. |
| **Native iOS Configuration** | Registered inside Xcode project bundle resources (`GoogleService-Info.plist`). | Full compatibility with iOS security standards, push notification services, and Apple guidelines. |
| **Native Android Configuration** | Google Services Gradle plugin configuration (`google-services.json`). | Native Android integration without runtime configuration overhead. |
| **Local Authentication** | Native fingerprint and Face ID verification via device biometric hardware. | High-speed security checkpoint safeguarding sensitive financial records. |
| **Local Notifications** | Timezone-aware local background reminder engine. | Reliable EMI due date reminders without requiring third-party marketing servers. |
| **PDF & Printing** | Vector document rendering engine generating A4 loan statements. | Official, print-ready amortization schedules for offline archiving and sharing. |

---

## 4. Design System, Typography & Global Visual Tokens

### Design Philosophy
PayWise is styled with an elevated **Deep Navy Blue & Royal Blue Glassmorphism** visual language. Frosted translucent surfaces, multi-layered depth, anti-glare backdrops, and high-contrast typography combine aesthetic elegance with financial clarity.

### Primary Color Tokens

| Color Name | Hex Code / Value | Semantic Role & Where It Is Used |
|---|---|---|
| **Primary Deep Navy** | `#1E3C72` | Primary brand anchor; hero card gradients, active tab indicators, and primary button fills. |
| **Primary Royal Blue** | `#2A5298` | Secondary brand anchor; right-side hero gradient, section headers, and active toggles. |
| **Primary Indigo Accent** | `#3B4CCA` / `#2A36B1` | Interactive accents, action buttons, slider active tracks, and focus borders. |
| **Tech Indigo Accent** | `#4F46E5` / `#6366F1` | Dark mode active tab gradients, interactive badges, and slider thumbs. |
| **Success Emerald** | `#10B981` / `#2E7D32` | Positive financial health; principal cleared, interest saved figures, and paid-off badges. |
| **Warning Amber** | `#F59E0B` / `#D97706` | Cost and attention indicators; interest burden portions, upcoming payment notices, and night mode icons. |
| **Urgent Crimson** | `#EF4444` / `#DC2626` | Liability alerts; overdue payments, loan deletion actions, and error banners. |
| **Light Canvas Background** | `#F8F9FA` / `#F7F8FE` | Light mode surface; crisp, glare-free off-white backdrop for comfortable daytime viewing. |
| **Light Card Surface** | `#FFFFFF` | Pure white elevated cards with subtle ambient shadows. |
| **Light Soft Container** | `#EEF2FF` / `#EBF1F9` | Soft navy/indigo container backgrounds for icons and chips. |
| **Dark Obsidian Background** | `#121212` / `#0D0F1B` | Dark mode surface; deep OLED-friendly black backdrop minimizing battery drain and eye strain. |
| **Dark Card Surface** | `#1E1E1E` / `#16192A` | Elevated dark gray cards with translucent frosted glass borders. |
| **Dark Soft Container** | `#1E3C72` with 25% opacity | Translucent navy container backgrounds for dark mode icon boxes and chips. |

### Functional Banner & Toast Tokens

| Token Name | Background Hex | Badge / Button Hex | Text Hex | Semantic Function |
|---|---|---|---|---|
| **Success Banner** | `#ECFDF5` | `#10B981` / `#16A34A` | `#065F46` / `#047857` | Confirms successful loan creation and payment recording. |
| **Undo Banner** | `#F3F0FF` | `#6C5CE7` | `#1E1B4B` / `#6B7280` | Displays 8-second countdown timer allowing instant recovery of deleted loans. |
| **Error Banner** | `#FDF2F2` | `#DC2626` | `#991B1B` / `#B91C1C` | Alerts user to invalid inputs, tenure violations, or authentication errors. |
| **Donut Principal** | N/A | `#2979FF` (Vibrant Blue) | N/A | Principal portion slice in portfolio donut chart. |
| **Donut Interest** | N/A | `#FF9100` (Vibrant Amber) | N/A | Total interest payable slice in portfolio donut chart. |

### Adaptive Theme System (Phone System Sync + Manual Override)
* **Automatic Phone Theme Sync**: Out of the box, PayWise reads the operating system theme. If your phone is set to Dark Mode, the app opens in Dark Mode. If your phone is in Light Mode, the app opens in Light Mode.
* **Real-Time Dynamic Tracking**: If your phone shifts to Dark Mode at sunset, PayWise smoothly updates its theme in real-time.
* **Manual Override**: If you prefer Dark Mode during the daytime, toggling the switch in Settings permanently locks the app into your choice (`Always Dark` or `Always Light`).
* **One-Tap "Auto" Reset**: Whenever a custom theme is active, an "Auto" button appears in Settings to restore operating system tracking with a single tap.

### Screen-by-Screen Typography & Layout Parameters

| Screen Name | UI Component | Font Size | Font Weight | Color Token (Light / Dark) | Layout & Styling |
|:---|:---|:---|:---|:---|:---|
| **Splash Screen** | App Logo Title | `38pt` | ExtraBold (`w800`) | Light: `#1E1B4B`<br>Dark: `#FFFFFF` | Elastic entrance, letter spacing `-0.5px` |
| | Tagline Subtitle | `14pt` | Medium (`w500`) | Light: `#64748B`<br>Dark: `#94A3B8` | Staggered fade, letter spacing `0.4px` |
| **Login Screen** | Header Welcome | `28pt` | ExtraBold (`w800`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Horizontal padding `20px` |
| | Input Field Text | `14.5pt` | SemiBold (`w600`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Fill `#FAFAFE`, border `#E2E8F0`, radius `14px` |
| | Login Button | `16pt` | Bold (`w700`) | `#FFFFFF` | Gradient `[#2A36B1, #3B4CCA]`, height `54px`, radius `16px` |
| **Register Screen** | Screen Title | `28pt` | ExtraBold (`w800`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Outer padding `20px` |
| | Form Labels | `14pt` | Bold (`w700`) | Light: `#0F172A`<br>Dark: `#E2E8F0` | Bottom margin `8px` |
| **Dashboard Screen** | User Welcome Header | `20pt` | ExtraBold (`w800`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Subtitle with dynamic date display |
| | Total Outstanding | `32pt` | ExtraBold (`w800`) | `#FFFFFF` | Gradient hero card `[#1E3C72, #2A5298]`, radius `24px` |
| | Outstanding Label | `13pt` | Medium (`w500`) | `Colors.white70` | Letter spacing `0.2px` |
| | Trend Badge | `12pt` | Bold (`w700`) | Green: `#2E7D32`<br>Red: `#E53935` | Capsule pill container with `0.2` opacity background |
| | Donut Center Value | `22pt` | ExtraBold (`w800`) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Centered within vector chart ring |
| | Loan Card Title | `16pt` | Bold (`w700`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Elevated card surface, radius `20px` |
| | Loan Card Lender | `12pt` | Medium (`w500`) | Light: `#64748B`<br>Dark: `#A0A7C2` | Leading category icon box `#EEF2FF` |
| **Add Loan Screen** | Screen Title | `26pt` | ExtraBold (`w800`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Top row with 44px back button |
| | Field Labels | `14pt` | Bold (`w700`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Margin bottom `8px` |
| | Input & Hints | `14.5pt` | SemiBold (`w600`) | Text: `#0F172A`<br>Hint: `#94A3B8` | Soft indigo prefix box `#EEF2FF`, radius `14px` |
| | Save Loan Button | `15.5pt` | Bold (`w700`) | `#FFFFFF` | Gradient `[#2A36B1, #3B4CCA]`, height `54px`, radius `16px` |
| **Simulation Screen** | Tab Bar Headers | `13pt` | Bold (`w700`) | Active: `#FFFFFF`<br>Inactive: `#64748B` | Rounded pill tab bar with gradient selection |
| | Selected Loan Card | `15pt` | Bold (`w700`) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Rounded glass container, opens loan picker |
| | Input Values | `16pt` | ExtraBold (`w800`) | Light: `#1E3C72`<br>Dark: `#6366F1` | Integrated with right-aligned Done checkmark button |
| **Loan Details Screen** | Hero Balance | `30pt` | ExtraBold (`w800`) | Light: `#1E3C72`<br>Dark: `#FFFFFF` | Prominent overview balance card |
| | Amortization Header | `16pt` | Bold (`w700`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Top bar with PDF export action icon |
| **Info / Learn Screen** | Hero Card Title | `24pt` | ExtraBold (`w800`) | `#FFFFFF` | Indigo gradient card `[#1E3C72, #2A5298]` |
| | Glossary Term | `15pt` | Bold (`w700`) | Light: `#1E3C72`<br>Dark: `#90B3E8` | Expandable terminology cards |
| **Profile & Settings** | Display Name | `22pt` | ExtraBold (`w800`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Top curved profile card |
| | Tile Title | `15pt` | Bold (`w700`) | Light: `#0F172A`<br>Dark: `#FFFFFF` | Leading icon box `#EBF1F9`, icon `#1E3C72` |
| | Tile Subtitle | `12pt` | Regular (`w400`) | `#64748B` | Switch active track `#1E3C72` |
| **Toast Notifications** | Undo Toast Title | `14.5pt` | Bold (`w700`) | Light: `#1E1B4B`<br>Dark: `#FFFFFF` | Lavender container `#F3F0FF`, badge `#6C5CE7` |
| | Success Toast Title | `14.5pt` | Bold (`w700`) | Light: `#065F46`<br>Dark: `#FFFFFF` | Emerald container `#ECFDF5`, badge `#10B981` |
| | Error Toast Title | `14.5pt` | Bold (`w700`) | Light: `#991B1B`<br>Dark: `#FECDD3` | Red container `#FDF2F2`, badge `#DC2626` |

---

## 5. Navigation Architecture & Floating Capsule Shell

PayWise utilizes a custom floating capsule navigation bar elevated above the screen content:

* **Capsule Geometry**:
  * Height: `68px`
  * Horizontal Margin: `16px`
  * Bottom Floating Margin: `10px`
  * Border Radius: `36px`
  * Ambient Depth Shadow: Multi-layered box shadow with `16px` blur radius
* **Four Primary Destinations**:
  1. **Home (Dashboard)**: Portfolio summary, active loan cards, quick repayment actions, and payoff progress.
  2. **Simulate**: Interactive playground for Extra EMI, Lump Sum prepayments, and Refinancing analysis.
  3. **Learn (Info)**: Financial literacy handbook, core terminology glossary, and interest reduction strategies.
  4. **Settings (Profile)**: User profile management, theme toggles, biometric security, and notification settings.
* **Elevated Floating Action Button (FAB)**: Centered quick-action button allowing users to add a new loan from anywhere in the app with one tap.
* **Global Smooth Page Route Transitions**: All screens transition using a horizontal slide with an `easeOutCubic` curve and a simultaneous fade transition.

---

## 6. Financial Engines & Mathematical Logic

### 1. Equated Monthly Instalment (EMI) Formula
PayWise computes reducing balance EMIs using the standard international banking formula:

$$\text{EMI} = \frac{P \times r \times (1+r)^n}{(1+r)^n - 1}$$

Where:
* $P$ = Principal Loan Amount
* $r$ = Monthly Interest Rate ($\text{Annual Interest Rate} \div 12 \div 100$)
* $n$ = Loan Tenure in Months

For flat-rate financing models, interest is calculated on the total principal for the full duration and distributed evenly across monthly payments.

### 2. Multi-Mode Prepayment Calculation Engine
* **Extra Monthly EMI Mode**: Simulates adding a recurring extra amount to every future installment. The extra money is deducted directly from the remaining principal, exponentially shrinking future interest accumulation and reducing total tenure.
* **Annual Recurring Bonus Mode**: Simulates contributing a fixed annual bonus (e.g., ₹50,000 every year during Diwali or fiscal year-end). The engine recalculates the amortization curve at 12-month intervals.
* **Custom Multi-Lump Sum Mode**: Allows inputting specific lump sums at arbitrary months (e.g., ₹25,000 in Month 6, ₹75,000 in Month 18).
* **Refinancing & Balance Transfer Simulator**: Evaluates switching a loan to another lender offering a lower interest rate:
  * Factors in processing fees, balance transfer charges, and documentation costs.
  * Calculates new monthly installment amounts and monthly budget savings.
  * Computes the exact break-even point in months.

### 3. Indian Banking & RBI Compliance Guardrails
* **Mandatory Category Tenure Caps**:
  * Home Loans: Up to 360 Months (30 Years)
  * Loan Against Property (LAP) / Business Loans: Up to 240 Months (20 Years)
  * Education Loans: Up to 180 Months (15 Years)
  * Car / Four-Wheeler Loans: Up to 96 Months (8 Years)
  * Personal Loans: Up to 84 Months (7 Years)
  * Two-Wheeler Loans: Up to 60 Months (5 Years)
  * Gold Loans: Up to 36 Months (3 Years)
* **Interest Rate Ceiling**: Maximum allowed interest rate capped at 50% to prevent predatory or erroneous entries.
* **Single Payment Per Day Guard**: Restricts payments to one record per loan per calendar day, preventing duplicate accidental deductions.
* **Persistent 33-Bank Autocomplete**: Real-time autocomplete suggestions covering major Indian Public Sector (SBI, PNB, Bank of Baroda, Canara, etc.) and Private Sector Banks (HDFC, ICICI, Axis, Kotak, IndusInd, etc.).

---

## 7. Smart Notification & Due Alert Engine

PayWise runs a local, timezone-aware push notification engine to ensure borrowers stay ahead of payment schedules without late fees:

1. **Advance Notice Reminder**: Triggers 3 days before an EMI due date to give users time to arrange funds.
2. **Due Tomorrow Warning**: Triggers 24 hours before payment day as an urgent balance check.
3. **Due Today Morning Alert**: Triggers at 9:00 AM on the scheduled payment day.
4. **Dynamic Week-Ahead Notice**: Triggers 7 days ahead for large commitments like home mortgages.
5. **Overdue Escalation Notice**: Triggers if an EMI due date passes without a payment being recorded, helping protect credit scores.

Every notification category can be individually toggled in Settings alongside a master switch that silences all alerts.

---

## 8. Exhaustive Screen-by-Screen Walkthrough

### Screen 1: Animated Splash & Startup
* **Visual Presentation**: High-resolution centered PayWise emblem enveloped in a rotating shimmer ring, floating ambient particles, smooth sliding "Pay" and "Wise" typography, and the tagline *"Smart Loans, Smarter You"*.
* **Background Execution**: During the 1.1-second entrance animation, the app pre-initializes Firebase, verifies biometric hardware, checks local encryption keys, and loads cached loans from disk.
* **Transition**: Smooth cross-fade into the authentication gateway.

### Screen 2: Welcome & Onboarding Screen
* **Target Audience**: First-time users or signed-out users.
* **Visuals**: Clean welcoming hero graphic, value proposition carousel highlighting interest reduction, debt freedom timelines, and zero-snooping privacy guarantees.
* **Actions**: Direct buttons to Log In or Register.

### Screen 3: Authentication Suite
* **Login Screen**: Form with floating labels for Email and Password, password visibility toggle, one-tap Google Sign-In, and a "Forgot Password?" dialog that dispatches secure Firebase password reset links.
* **Google Account Chooser**: Clears cached authentication state prior to prompting, forcing Google Play Services to always present the multi-account chooser modal.
* **Register Screen**: Name, email, password, and password confirmation fields with real-time validation, creating both a Firebase Auth account and a Firestore user document simultaneously.
* **Session Guardian (AuthWrapper)**: Monitors live auth state. If biometric security is enabled, it requires Face ID / Fingerprint verification before presenting the dashboard.

### Screen 4: Main Navigation Shell
* **Design**: 68px floating frosted glass capsule navigation bar.
* **Haptic Feedback**: Subtle vibration on tab transitions.
* **Central FAB**: Elevated circular button for adding loans from any tab.

### Screen 5: Dashboard Screen (Financial Command Center)
* **Top Hero Card**: Displays total outstanding balance in large formatted currency (`₹`), total monthly commitment (sum of all EMIs due this month), and a circular payoff progress ring.
* **Category Filter Tabs**: Horizontally scrollable chip filter (All, Home, Car, Personal, Education, Credit Card, Gold, Business).
* **Active Loan Cards**: Shows title, lender, balance, interest rate, and next EMI due date with a linear progress bar of principal paid.
* **Card Swipe Gestures**:
  * **Swipe Right**: Instantly records one monthly EMI payment, recalculates future balance, logs the transaction, and displays a success toast.
  * **Swipe Left**: Prompts to delete or archive the loan, triggering an 8-second undo toast banner.
* **Portfolio Donut Chart**: Interactive pie chart breaking down principal cost (`#2979FF`) versus total interest cost (`#FF9100`).
* **Celebration State**: When all active loans are paid off, the dashboard displays a celebratory banner congratulating the user on achieving debt freedom.

### Screen 6: Add Loan Screen
* **Input Fields**: Loan Title, Lender Name (with 33-bank autocomplete), Principal Amount, Interest Rate (capped at 50%), Tenure in Months or Years, and Loan Start Date picker.
* **Category Chips**: Home, Car, Personal, Education, Credit Card, Two-Wheeler, Gold, and Business with contextual icons and automatic RBI tenure caps.
* **Interest Model**: Reducing balance vs. flat rate selection.
* **Live Calculation Card**: Dynamically updates Monthly EMI, Total Interest Payable, and Total Repayment Amount in real-time as you type.

### Screen 7: Loan Details & Amortization Screen
* **Overview Card**: Loan snapshot detailing original principal, current balance, interest rate, tenure remaining, and next due date.
* **Month-by-Month Amortization Table**: Full schedule detailing Month, EMI Amount, Principal component, Interest component, and Closing Balance.
* **Payment History Ledger**: Audit trail of every payment recorded, including date, amount, and payment type (Scheduled EMI vs. Prepayment).
* **Record Custom Payment Dialog**: Modal allowing retroactive payment entry with custom calendar dates (restricted to today or past dates).
* **Print-Ready PDF Statement Export**: Generates an A4 amortization statement with custom branding, lender metadata, and table data, integrated with AirPrint, Android Print Spooler, and document sharing.

### Screen 8: Loan Simulation Screen
* **Tab 1: Extra Monthly EMI**: Slider and text input to simulate adding extra monthly payments, calculating exact interest saved and years shaved off the loan.
* **Tab 2: Lump Sum Prepayment**: Simulates single lump sums, recurring annual bonus payments, or custom multi-lump sum schedules across tenure.
* **Tab 3: Refinancing & Balance Transfer**: Evaluates switching to a lower interest rate, factoring in bank processing fees, and computing net lifetime savings and break-even months.
* **iOS Keyboard Ergonomics**: Features right-aligned `(✓)` Done buttons inside number inputs, background tap-to-dismiss gesture support, and drag-to-dismiss behavior on all scrollable views.

### Screen 9: Loan Analysis & Strategy Screen
* **Debt-to-Income (DTI) Evaluation**: Calculates total monthly debt payments against income to identify financial risk levels.
* **Strategy Comparison**:
  * **Avalanche Method**: Directs extra payments to the highest-interest loan first to maximize mathematical interest savings.
  * **Snowball Method**: Directs extra payments to the smallest-balance loan first to build psychological momentum.

### Screen 10: Loan History & Cleared Debt Archive
* **Debt-Free Hall of Fame**: Displays completed loans that have reached zero balance.
* **Cumulative Metrics**: Highlights lifetime principal cleared and total interest saved through early prepayments.

### Screen 11: Learn & Financial Literacy (Info) Screen
* **Core Foundations Glossary**: Definitions of Principal, EMI, Tenure, Amortization, APR, Reducing Balance, Foreclosure, and Processing Fees.
* **Strategic Guides**: Tactics for negotiating lower interest rates with existing banks, prepayment dos and don'ts, and credit score preservation tips.

### Screen 12: Profile & Settings Screen
* **User Profile Header**: Displays user avatar, full name, and authenticated email address.
* **Appearance (Dark Mode)**: Dynamic system tracking switch with manual override and an "Auto" reset button.
* **Biometric Security**: Switch to activate Face ID / Touch ID / Fingerprint lock.
* **Interaction (Swipe Actions)**: Toggle to enable or disable swipe gestures on dashboard cards.
* **Notification Preferences**: Independent toggles for Advance, Due Tomorrow, Due Today, and Overdue alerts.
* **Danger Zone**: Access to the 7-Day Grace Period account deletion workflow.
* **Version & Copyright**: Displays `Version 1.0.0` and `© 2026 PayWise. All rights reserved.`.

### Screen 13: Edit Profile Screen
* Update display name, phone number, and avatar with real-time Firebase Auth and Firestore profile synchronization.

### Screen 14: Delete Account Screen
* Explains the 7-day grace period, preventing emotional or accidental data loss.
* Provides actions to schedule deletion with a 7-day safety window, cancel an active deletion request, or execute immediate permanent deletion.

---

## 9. Interactive UI Ergonomics & Toast System

### Floating Toast System with 8-Second Undo
* **Root Overlay Hosting**: Toasts float `90px` above the bottom navigation bar via the root navigator overlay, eliminating overlay collision exceptions.
* **Soft Deletion Staging**: When a loan is deleted, it is hidden from the UI and staged for 8 seconds.
* **Instant Recovery**: Tapping "Undo" on the lavender toast cancels deletion immediately. If 8 seconds elapse without undo, permanent deletion from Firestore executes in the background.
* **Success Banners**: Slide-up emerald green banners confirm loan saves and payment records.

### App Launcher Icons Setup
* **Mathematical Center Alignment**: The PayWise emblem is centered to the exact **Alpha Center of Mass `(511.6, 510.8)`** inside a `1024x1024` master canvas.
* **Platform Assets**:
  * Android adaptive mipmap icons (`hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) with adaptive vector foregrounds.
  * iOS asset catalog (`AppIcon.appiconset`) with full Xcode bundle compliance.

---

## 10. Build, Distribution & Version Specifications

### Production Release Targets

| Architecture Target | Platform | Description |
|:---|:---|:---|
| **ARM 64-bit (`arm64-v8a`)** | Android | Production architecture for modern smartphones. |
| **ARM 32-bit (`armeabi-v7a`)** | Android | Compatible with legacy Android devices. |
| **x86 64-bit (`x86_64`)** | Android | Optimized for Android Emulators & ChromeOS. |
| **Universal IPA Package** | iOS | Complete release package for iPhone & iPad distribution. |

### Version & Legal Attribution
* **Release Version**: `1.0.0`
* **Build Number**: `1`
* **Legal Attribution**: © 2026 PayWise. All rights reserved.
