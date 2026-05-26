# Expense Tracker
A modern, high-performance Fintech mobile application built with the Flutter framework. This project demonstrates advanced, dependency-free state management, reactive local persistence with Hive, and an adaptive, high-fidelity UI inspired by minimalist premium financial SaaS designs.

## Features
### Dynamic Financial Dashboard
Real-time balance tracking utilizing interactive gradient cards that adapt instantly to global preference changes.

### Interval Timeline Filtering
Interactive, contextual interval sorting across the entire app workspace. Users can jump between This Week, This Month, and All Time view scopes to update ledger cards, total balance aggregates, and visual pie charts on the fly.

### Custom Preference Engine
Centralized state management for application behavior and configuration streams without relying on bulky third-party state packages or complex boilerplates.

### AMOLED Premium Dark Mode
High-contrast, pitch-black themes designed specifically for modern mobile AMOLED displays to drastically reduce eye strain and optimize battery power profiles.

### Global Currency Customization
App-wide reactive currency switching (e.g., $, €, ₨, £) that automatically filters and formats text field input prefixes, ledger tiles, and analytics instantly.

### Spending Analysis
Interactive telemetry data visualization using the fl_chart library to break down category-wise expense proportions dynamically with reactive legends.

### Allocation Progress Tracks
Visual budget-to-spend tracking component bars that automatically recalculate boundaries and shift indicator colors depending on active UI theme metrics.

### Biometric Gate & Core Security
Seamless security verification layer utilizing on-device computer vision for face detection upon application initialization. The state layer handles a secure bypass condition—automatically routing users straight to the dashboard if biometrics are explicitly deactivated in app settings.

### Local NoSQL Persistence
Ultra-fast local database caching utilizing Hive to stream raw binary transaction objects and retain global preference metrics instantly across app system lifecycles.

## Architecture & State Flow
The application relies on a completely decoupled, reactive architectural pipeline. Instead of introducing heavy state management overhead, it solves cross-module communication cleanly using Flutter's native ValueNotifier pattern combined with Hive for synchronous disk persistence.
[ Settings Screen ] ──(Trigger Preference Change)──► [ AppStateManager ]
                                                             │
                                                    (Updates Notifier)
                                                             │
                                                             ▼
[ Dashboard / Security / Charts ] ◄──(Reactive Rebuild via ValueListenableBuilder)
 
## Tech Stack
Framework: Flutter (Multi-Platform Mobile System Environment)

Database Engine: Hive Flutter (Lightweight NoSQL key-value storage)

State Architecture: Reactive Engine utilizing native ValueNotifier & ValueListenableBuilder hooks

Computer Vision: Google ML Kit Face Detection

Hardware Interfacing: Flutter Camera Library

Data Visualization: fl_chart

## Project Structure
lib/
├── models/           # Data models & Hive adapters (Transaction         blueprints & filtering logic)
├── screens/          # App-level UI Views (Dashboard, Settings, CategoryDetail, SecurityScreen)
├── services/         # Central Business Logic Controllers & Notifiers (AppStateManager)
├── widgets/          # Reusable presentation nodes (AllocationCard, SpendingChart, TimelineSelector)
└── main.dart         # Native bindings, global box configuration initialization, and root Material styling

## Getting Started
### Prerequisites
Before running the project, make sure you have the Flutter SDK installed on your development machine:

Flutter SDK (v3.0.0 or higher)

Android Studio / Xcode

Dart SDK

### Installation & Execution
### Clone the repository:
git clone https://github.com/anammemon091/Expense_Tracker.git
cd hng_expense_tracker

### Fetch packages and generate platform branding assets:
flutter pub get
dart run flutter_launcher_icons

### Run the application:
flutter run