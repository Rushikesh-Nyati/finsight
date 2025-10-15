📱 FinSight - AI-Powered Personal Finance Tracker
<p align="center"> <em>A privacy-first personal finance app with intelligent SMS transaction categorization</em> </p>
🌟 Overview
FinSight is a comprehensive personal finance management application built with Flutter and Python Flask. It automatically categorizes your financial transactions from SMS messages using on-device machine learning, provides AI-powered budget suggestions, spending forecasts, and personalized savings plans - all while keeping your sensitive data secure on your device.​

✨ Key Features
🔒 Privacy-First Architecture - All SMS processing happens on-device

🤖 AI-Powered Categorization - TensorFlow Lite model for automatic transaction categorization

📊 Smart Budget Planning - AI-generated budget suggestions based on your spending patterns

📈 Spending Forecasts - Predictive analytics for 30-day spending projections

💰 Savings Goal Planner - Personalized savings plans with spending cut recommendations

📱 Manual Expense Tracking - Add transactions manually with intuitive forms

📉 Visual Analytics - Interactive charts and graphs for spending insights

🎨 Modern UI/UX - Clean, intuitive Material Design interface

🏗️ Architecture
Tech Stack
Frontend (Flutter)
Framework: Flutter 3.0+

Language: Dart

State Management: Provider pattern

Local Database: SQLite (sqflite)

ML Integration: TensorFlow Lite for on-device inference

Data Visualization: fl_chart

HTTP Client: http package

SMS Access: telephony package

Backend (Python/Flask)
Framework: Flask 2.3.3 with CORS support

Data Processing: Pandas 2.0.3, NumPy 1.24.3

Machine Learning: Scikit-learn 1.3.0

Forecasting: Prophet 1.1.4

Database: SQLite for data persistence

📁 Project Structure
text
finsight_app/
├── finsight_app/
│   ├── frontend/                 # Flutter application
│   │   ├── lib/
│   │   │   ├── models/          # Data models (Transaction, Category)
│   │   │   ├── providers/       # State management (TransactionProvider)
│   │   │   ├── screens/         # UI screens
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── budget_screen.dart
│   │   │   │   ├── forecast_screen.dart
│   │   │   │   ├── savings_planner_screen.dart
│   │   │   │   └── manual_expense_screen.dart
│   │   │   ├── services/        # Business logic
│   │   │   │   ├── database_service.dart
│   │   │   │   ├── sms_parser_service.dart
│   │   │   │   ├── sms_ml_service.dart
│   │   │   │   └── api_service.dart
│   │   │   └── main.dart
│   │   ├── assets/              # ML model and resources
│   │   │   └── sms_categorizer.tflite
│   │   ├── pubspec.yaml
│   │   └── README.md
│   │
│   └── backend/                 # Python Flask API
│       ├── app.py              # Main Flask application
│       ├── requirements.txt    # Python dependencies
│       ├── test_api.py        # API testing script
│       └── README.md
│
├── PROJECT_SUMMARY.md
└── README.md                    # This file
🚀 Getting Started
Prerequisites
For Frontend:
Flutter SDK 3.0.0 or higher (Install Flutter)

Dart SDK

Android Studio / VS Code with Flutter extensions

Android device or emulator for testing

For Backend:
Python 3.8 or higher

pip package manager

Virtual environment (recommended)

Installation
1. Clone the Repository
bash
git clone https://github.com/YOUR-USERNAME/finsight.git
cd finsight
2. Backend Setup
bash
# Navigate to backend directory
cd finsight_app/backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run Flask server
python app.py
The backend server will start on http://localhost:5000.​

3. Frontend Setup
bash
# Navigate to frontend directory (from project root)
cd finsight_app/frontend

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
Choose your target device when prompted.​

📱 Features in Detail
1. Onboarding Flow
Welcome screen introducing app benefits

SMS permission request with privacy explanation

Initial SMS analysis and automatic categorization​

2. Smart Dashboard
Monthly Spending Summary - Overview of current month expenses

Category-Wise Breakdown - Interactive pie charts showing spending distribution

Recent Transactions - Chronological list of latest transactions

Quick Actions - Fast access to all features​

3. Manual Expense Entry
Add transactions manually with form validation

Choose from 10 predefined categories with icons

Date picker for transaction date

Merchant name and amount input​

4. AI Budget Planning
Automatic budget suggestions based on historical data

Budget vs spending comparison charts

Category-wise budget tracking with progress indicators

10% buffer included in suggestions for flexibility​

5. Spending Forecast
30-day spending predictions using statistical analysis

Trend visualization with line charts

Daily forecast breakdown

Confidence indicators for predictions​

6. Savings Goal Planner
Set savings goals with target amount and timeline

Discretionary vs essential spending analysis

Personalized spending cut recommendations

Achievability assessment​

🔐 Privacy & Security
FinSight takes your privacy seriously:​

✅ On-Device Processing - All SMS parsing happens locally on your device

✅ No Data Transmission - Sensitive SMS content never leaves your device

✅ Local Storage - All transactions stored in device SQLite database

✅ ML Privacy - TensorFlow Lite model runs entirely on-device

✅ Aggregated Analytics - Backend only receives anonymized spending patterns

✅ No Cloud Dependencies - Works offline for core features

🌐 API Documentation
Base URL
text
http://localhost:5000

🧪 Testing
Backend API Testing
bash
cd finsight_app/backend
python test_api.py
This will test all API endpoints and verify responses.​

📋 Supported Transaction Categories
FinSight categorizes transactions into these predefined categories:​

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
Dependencies
Flutter (pubspec.yaml):​
text
dependencies:
  provider: ^6.1.1        # State management
  sqflite: ^2.3.0        # Local database
  http: ^1.1.0           # API communication
  fl_chart: ^0.65.0      # Data visualization
  permission_handler: ^11.0.1  # Permissions
  telephony: ^0.2.0      # SMS access
  intl: ^0.18.1          # Date formatting
Python (requirements.txt):​
text
Flask==2.3.3
Flask-CORS==4.0.0
pandas==2.0.3
numpy==1.24.3
scikit-learn==1.3.0
prophet==1.1.4
Contributing
We welcome contributions! Please follow these steps:

Fork the repository

Create a feature branch (git checkout -b feature/AmazingFeature)

Commit your changes (git commit -m 'Add some AmazingFeature')

Push to the branch (git push origin feature/AmazingFeature)

Open a Pull Request

📝 License
This project is developed as an academic project for educational purposes.

👥 Team
Developed by Team TKN for Semester 5 SEPM Project.

🙏 Acknowledgments
Flutter team for the amazing framework

TensorFlow team for TensorFlow Lite

Open-source community for various packages used

📞 Support
For issues, questions, or suggestions:

Open an issue on GitHub

Contact the development team

🔮 Future Enhancements
 Advanced ML model training pipeline

 Enhanced forecasting with Prophet integration

 Investment portfolio tracking

 Bill payment reminders

 Export functionality (CSV, PDF)

 Multi-currency support

 Dark theme support

 Cloud sync (optional)

 Expense splitting for shared expenses

 Receipt scanning with OCR

<p align="center">Made with ❤️ by Team TKN</p>
