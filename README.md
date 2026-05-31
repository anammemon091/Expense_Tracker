# Expense Tracker
A modern, high-performance Fintech mobile application built with the Flutter framework. This project demonstrates advanced, dependency-free state management, reactive local persistence with Hive, and an adaptive, high-fidelity UI inspired by minimalist premium financial SaaS designs.

## Features

### 🔄 Auto-Leap Recurring & Subscription Engine
Pure manual billing logs are elevated with an automated time-series cron simulator. The application registers customizable tracking profiles (e.g., Netflix, Spotify, Gym memberships) and utilizes an onboarding catch-up loop. Upon every initialization, the runtime engine processes overdue cycles, automatically injects missing interval logs into the local ledger, updates internal dates, and syncs balances on the fly.

### 🔮 30-Day Future Impact Forecast Matrix
A proactive financial warning telemetry system integrated directly into the primary dashboard view. The engine scans active subscription rules, analyzes impending calendar targets, and displays a dynamic aggregate forecast of automated deductions due to deploy within the next 30 days to help users prevent liquidity strain.

### 🛠️ Dynamic Category Engine
Pure hardcoded structures are eliminated. The system features a fully state-driven mapping layout, allowing users to inject, modify, and manage custom transaction tags equipped with distinctive color themes and customizable visual icon profiles straight from the settings context.

### 📊 Reactive Expense Analytics & Pie Charts
Dynamic telemetry data visualization leveraging the `fl_chart` library. The dashboard segment automatically mirrors runtime lookup values, matching segment slices instantly with the custom colors defined in your active categories while automatically filtering out zero-value channels.

### 📈 Smart Budget Allocation Tracks
Visual budget-to-spend tracking component bars that automatically recalculate remaining allowance boundaries on the fly. The engine monitors multi-currency updates reactively and flashes immediate, high-fidelity structural warning indicators if any dynamic category crosses into an over-budget threshold.

### 🕒 Interval Timeline Filtering
Interactive, contextual interval sorting across the entire app workspace. Users can jump between This Week, This Month, and All Time view scopes to update ledger cards, total balance aggregates, and visual pie charts dynamically.

### ⚙️ Centralized Custom Preference Engine
Decoupled state architecture managing multi-currency toggles (e.g., $, €, ₨, £), timeline states, and interface behavioral configurations without adding bulky third-party boilerplate frameworks.

### 🔌 AMOLED Premium Dark Mode
High-contrast, pitch-black themes designed specifically for modern mobile AMOLED displays to drastically reduce eye strain and optimize battery power profiles.

### 🔒 Biometric Gate & Core Security
Seamless security verification layer utilizing on-device computer vision for face detection upon application initialization. The state layer handles a secure bypass condition—automatically routing users straight to the dashboard if biometrics are explicitly deactivated in app settings.

### 💾 Local NoSQL Multi-Box Persistence
Ultra-fast local database caching utilizing Hive to stream raw binary transaction objects and retain global preference metrics instantly. The storage tier uses structurally independent binary boxes (`transactions_box`, `categories_box`, and `recurring_box`) to isolate data structures and enforce lightning-fast read/write cycles.

## Architecture & State Flow
The application relies on a completely decoupled, reactive architectural pipeline. Instead of introducing heavy third-party state management overhead, it solves cross-module communication cleanly using Flutter's native `ValueNotifier` pattern combined with Hive for synchronous disk persistence.
┌──────────────────────────────────────────────┐
              │               Settings Screen                │
              └──────────────────────┬───────────────────────┘
                                     │
                         (Trigger Preference Change)
                                     │
                                     ▼
              ┌──────────────────────────────────────────────┐
              │               AppStateManager                │
              │   [ValueNotifiers & Async Auto-Leap Engine]  │
              └──────────────┬────────────────────────┬──────┘
                             │                        │
                  (Updates UI Notifier)      (Syncs to Disk Storage)
                             │                        │
                             ▼                        ▼
 ┌──────────────────────────────────────┐  ┌────────────────────┐
 │   Dashboard / Security / Charts UI   │  │   Hive Storage     │
 │ (Reactive via ValueListenableBuilder)│  │ [Binary Multi-Box] │
 └──────────────────────────────────────┘  └────────────────────┘
 ## Tech Stack
* **Framework:** Flutter (Multi-Platform Mobile System Environment)
* **Database Engine:** Hive Flutter (Lightweight NoSQL binary key-value storage)
* **Code Generation:** Build Runner & Hive Generator (Automated type adapter indexing)
* **State Architecture:** Reactive Engine utilizing native `ValueNotifier` & `ValueListenableBuilder` hooks
* **Computer Vision:** Google ML Kit Face Detection
* **Hardware Interfacing:** Flutter Camera Library
* **Data Visualization:** `fl_chart`
* **Utilities:** `uuid` (Cryptographically secure unique asset ID generation)

## Project Structure
```text
lib/
├── models/         # Data blueprints, Object Schemas & generated Hive TypeAdapters
│   ├── transaction.dart          # Transaction records structure
│   ├── category_item.dart        # Custom dynamic categories model
│   └── recurring_blueprint.dart  # Recurring subscriptions & automated rules blueprint
├── screens/        # App-level UI Views & Scaffold viewports
│   ├── dashboard.dart            # Multi-sliver core dashboard with charts, ledger & forecast maps
│   ├── manage_subscriptions.dart # SaaS subscription setup, cycle management & tracking terminal
│   ├── category_detail_screen.dart # Deep-dive categorical timeline breakdowns
│   ├── settings_screen.dart      # Preference engines, dark toggle & dynamic tags hub
│   └── security_screen.dart      # Initialization biometric facial recognition verification gate
├── services/       # Central Business Logic Controllers, cron simulation & global hooks
│   └── app_state_manager.dart    # System pipelines execution hub & centralized ValueNotifiers
├── widgets/        # Reusable presentational view nodes & geometric asset rendering wrappers
│   ├── allocation_card.dart      # Line progress spend tracking limit bars
│   ├── spending_chart.dart       # High-fidelity analytics pie chart module
│   └── timeline_selector.dart    # Segmented interactive scope sorting tabs
└── main.dart       # Native bindings, storage configurations initialization, engine startup, and app shell

## Getting Started
### Prerequisites
Before running the project, make sure you have the Flutter SDK installed on your development machine:

Flutter SDK (v3.0.0 or higher)

Android Studio (with virtual emulator or physical ADB target) / Xcode (for iOS testing)

Dart SDK

### Installation & Execution
* ** Clone the repository:**

git clone [https://github.com/anammemon091/Expense_Tracker.git](https://github.com/anammemon091/Expense_Tracker.git)
cd Expense_Tracker

* **Fetch packages and structural modules:**

flutter pub get

* **Compile Object Adapters via Code Generator:**
Ensure all local NoSQL indices and database serializations are properly generated by triggering the background compiler:


dart run build_runner build --delete-conflicting-outputs

* **Run the application:**

flutter run