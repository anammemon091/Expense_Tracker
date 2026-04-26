# HNG Expense Tracker 🚀

A modern, high-performance Fintech mobile application built with Flutter. This project demonstrates advanced state management, local persistence with Hive, and a high-fidelity UI inspired by premium financial dashboards.

## ✨ Features

- **Dynamic Financial Dashboard**: Real-time balance tracking with gradient-styled cards.
- **Spending Analysis**: Interactive Pie Chart using `fl_chart` to visualize category-wise expenses.
- **Allocation Progress Bars**: Visual budget tracking for specific categories (Housing, Food, Transport).
- **Local Persistence**: Full offline capability using **Hive** for ultra-fast data storage and retrieval.
- **Biometric Security**: Integration ready for Face ID/Biometric authentication.
- **Customizable Budgets**: Settings module to edit spending limits per category.
- **Drill-down Ledger**: Detailed category screens to view specific transaction histories.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Database**: [Hive](https://pub.dev/packages/hive) (NoSQL local storage)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Icons**: Material Design Icons

## 📂 Project Structure
lib/
├── models/         # Data models (Transaction)
├── screens/        # UI Screens (Dashboard, Settings, Details)
├── widgets/        # Reusable UI components (AllocationCard, SpendingChart)
└── main.dart       # App entry point & Hive initialization