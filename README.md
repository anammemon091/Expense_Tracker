# Expense Tracker 
A modern, high-performance Fintech mobile application built with Flutter. This project demonstrates advanced, dependency-free state management, reactive local persistence with Hive, and an adaptive, high-fidelity UI inspired by minimalist premium financial SaaS designs.

## Features
### Dynamic Financial Dashboard: 
Real-time balance tracking utilizing interactive gradient cards that adapt instantly to global preferences.

### Preference Engine:
 Centralized state management for application behavior without relying on bulky third-party state packages.

### AMOLED Premium Dark Mode:
 High-contrast, pitch-black themes designed specifically for modern mobile displays to reduce eye strain and optimize battery performance.

### Global Currency Customization: 
App-wide reactive currency switching (e.g., $, €, ₨, £) that automatically formats inputs, ledgers, and budgets instantly.

### Spending Analysis:
 Interactive visualization using fl_chart to breakdown category-wise expenses dynamically.

### Allocation Progress Tracks:
 Visual budget-to-spend tracking component bars that automatically adapt colors and boundaries depending on active UI theme metrics.

### Local Persistence: 
Ultra-fast NoSQL local database caching utilizing Hive to persist transaction records and retain custom configurations across system lifecycles.

### Biometric Security: 
Seamless integration gate utilizing Face ID/Fingerprint authentication upon application initialization.

## Architecture & State Flow
The application relies on a decoupled, reactive architecture. Instead of introducing heavy state management boilerplates, it cleanly solves state synchronization across decoupled app modules using Flutter's native ValueNotifier pattern combined with Hive for persistence.

[ Settings Screen ] ──(Trigger Change)──► [ AppStateManager ]
                                                  │
                                          (Updates Notifier)
                                                  │
                                                  ▼
[ Dashboard / Main / Widgets ] ◄──(Rebuilds via ValueListenableBuilder)
## Tech Stack
Framework: Flutter (Cross-Platform Mobile Development)

Database: Hive Flutter (Lightweight NoSQL key-value storage)

State Management: Reactive Architecture utilizing native ValueNotifier & ValueListenableBuilder pairs

Charts: fl_chart

## Project Structure
Plaintext
lib/
├── models/           # Data models (Transaction blueprints)
├── screens/          # App-level UI Views (Dashboard, Settings, Details, Security)
├── services/         # Central Business Logic Controllers (AppStateManager)
├── widgets/          # Reusable presentation views (AllocationCard, SpendingChart)
└── main.dart         # Binding pipelines, global box initialization, and root Material instantiation
## Getting Started
Prerequisites
Before running the project, make sure you have the Flutter SDK installed on your machine.

Flutter SDK (v3.19.0 or higher recommended)

Android Studio / Xcode

Dart SDK

## Installation & Run
Clone the repository

```bash
git clone https://github.com/anammemon091/Expense_Tracker.git
cd hng_expense_tracker

### Fetch dependencies

flutter pub get

### Run the application

flutter run