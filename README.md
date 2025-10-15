# 📱 FinSight - AI-Powered Personal Finance Tracker
<p align="center"><em>A privacy-first personal finance app with intelligent SMS transaction categorization</em></p>

---

## 🌟 Overview
**FinSight** is a comprehensive personal finance management application built with **Flutter** and **Python Flask**.  
It automatically categorizes your financial transactions from SMS messages using on-device machine learning, provides **AI-powered budget suggestions**, **spending forecasts**, and **personalized savings plans** — all while keeping your sensitive data secure on your device.

---

## ✨ Key Features
- 🔒 **Privacy-First Architecture** – All SMS processing happens on-device  
- 🤖 **AI-Powered Categorization** – TensorFlow Lite model for automatic transaction categorization  
- 📊 **Smart Budget Planning** – AI-generated budget suggestions based on your spending patterns  
- 📈 **Spending Forecasts** – Predictive analytics for 30-day spending projections  
- 💰 **Savings Goal Planner** – Personalized savings plans with spending cut recommendations  
- 📱 **Manual Expense Tracking** – Add transactions manually with intuitive forms  
- 📉 **Visual Analytics** – Interactive charts and graphs for spending insights  
- 🎨 **Modern UI/UX** – Clean, intuitive Material Design interface  

---

## 🏗️ Architecture

### 🧩 Tech Stack

#### Frontend (Flutter)
- **Framework:** Flutter 3.0+  
- **Language:** Dart  
- **State Management:** Provider pattern  
- **Local Database:** SQLite (sqflite)  
- **ML Integration:** TensorFlow Lite for on-device inference  
- **Data Visualization:** fl_chart  
- **HTTP Client:** http package  
- **SMS Access:** telephony package  

#### Backend (Python/Flask)
- **Framework:** Flask 2.3.3 with CORS support  
- **Data Processing:** Pandas 2.0.3, NumPy 1.24.3  
- **Machine Learning:** Scikit-learn 1.3.0  
- **Forecasting:** Prophet 1.1.4  
- **Database:** SQLite for data persistence  

---

## 📁 Project Structure
```
finsight_app/
├── frontend/ # Flutter application
│ ├── lib/
│ │ ├── models/ # Data models (Transaction, Category)
│ │ ├── providers/ # State management (TransactionProvider)
│ │ ├── screens/ # UI screens
│ │ │ ├── onboarding_screen.dart
│ │ │ ├── dashboard_screen.dart
│ │ │ ├── budget_screen.dart
│ │ │ ├── forecast_screen.dart
│ │ │ ├── savings_planner_screen.dart
│ │ │ └── manual_expense_screen.dart
│ │ ├── services/ # Business logic
│ │ │ ├── database_service.dart
│ │ │ ├── sms_parser_service.dart
│ │ │ ├── sms_ml_service.dart
│ │ │ └── api_service.dart
│ │ └── main.dart
│ ├── assets/
│ │ └── sms_categorizer.tflite
│ ├── pubspec.yaml
│ └── README.md
│
└── backend/
├── app.py
├── requirements.txt
├── test_api.py
└── README.md
```
---

## 🚀 Getting Started

### 🧰 Prerequisites

#### For Frontend
- Flutter SDK 3.0.0+
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android device or emulator for testing

#### For Backend
- Python 3.8+
- pip package manager
- Virtual environment (recommended)

---

### 🛠️ Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/Rushikesh-Nyati/finsight.git
cd finsight
```
2. Backend Setup
```bash
cd finsight_app/backend
python -m venv venv
```
# Activate virtual environment
# On Windows:
```venv\Scripts\activate```
# On macOS/Linux:
```source venv/bin/activate```

# Install dependencies
```pip install -r requirements.txt```

# Run Flask server
```python app.py```
Backend will start on http://localhost:5000
3. Frontend Setup
```
cd finsight_app/frontend
flutter pub get
flutter run
```
📱 Features in Detail
1. Onboarding Flow

Welcome screen introducing app benefits

SMS permission request with privacy explanation

Initial SMS analysis and automatic categorization

2. Smart Dashboard

Monthly spending summary

Category-wise breakdown (interactive charts)

Recent transactions list

Quick access to key features

3. Manual Expense Entry

Form-based expense addition

10 predefined categories with icons

Date picker and merchant name fields

4. AI Budget Planning

Automatic budget suggestions from past data

Budget vs. spending comparison charts

Category-wise tracking with progress bars

5. Spending Forecast

30-day prediction using statistical models

Line chart trends and confidence indicators

6. Savings Goal Planner

Set savings goals with target and timeline

Personalized spending cut recommendations

🔐 Privacy & Security

FinSight ensures complete data privacy:

✅ On-device SMS processing
✅ No cloud data transmission
✅ Local SQLite storage
✅ ML inference via TensorFlow Lite
✅ Works offline for core features

🌐 API Documentation
Base URL
http://localhost:5000
🧪 Testing
```cd finsight_app/backend
python test_api.py
```

Runs all API endpoint tests and verifies responses.

📋 Supported Transaction Categories

🍔 Food & Dining

🛒 Shopping

🚗 Transportation

💊 Healthcare

🏠 Bills & Utilities

🎬 Entertainment

📚 Education

✈️ Travel

💰 Investments

❓ Uncategorized

🛠️ Development
Flutter Dependencies (pubspec.yaml)
```dependencies:
  provider: ^6.1.1
  sqflite: ^2.3.0
  http: ^1.1.0
  fl_chart: ^0.65.0
  permission_handler: ^11.0.1
  telephony: ^0.2.0
  intl: ^0.18.1
```
Python Dependencies (requirements.txt)
```Flask==2.3.3
Flask-CORS==4.0.0
pandas==2.0.3
numpy==1.24.3
scikit-learn==1.3.0
prophet==1.1.4
```
🤝 Contributing

Fork the repository

Create a new branch

```git checkout -b feature/AmazingFeature```


Commit your changes

```git commit -m "Add some AmazingFeature"```


Push and open a Pull Request

📝 License

This project is developed as an academic project for educational purposes.

👥 Team

Developed by Team TKN for Semester 5 SEPM Project.

🙏 Acknowledgments

Flutter team for the framework

TensorFlow team for TensorFlow Lite

Open-source community for various packages

🔮 Future Enhancements

Advanced ML model training pipeline

Enhanced forecasting using Prophet

Investment portfolio tracking

Bill payment reminders

CSV/PDF export

Multi-currency support

Dark theme support

Cloud sync (optional)

Expense splitting for shared expenses

OCR receipt scanning

<p align="center">Made with ❤️ by <strong>Team TKN</strong></p> ```
