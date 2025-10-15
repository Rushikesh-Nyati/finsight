# FinSight Personal Finance App

A privacy-first personal finance application that categorizes SMS transactions using on-device machine learning.

## Features

- **Privacy-First Design**: All SMS processing happens on-device
- **Automatic Transaction Categorization**: ML-powered SMS parsing
- **Manual Expense Entry**: Add transactions manually
- **Budget Planning**: AI-powered budget suggestions
- **Spending Forecasts**: Predictive analytics
- **Savings Planning**: Goal-based savings recommendations

## Technology Stack

### Frontend (Flutter)
- Framework: Flutter
- State Management: Provider
- Database: SQLite (sqflite)
- ML: TensorFlow Lite
- Charts: fl_chart
- HTTP: http package

### Backend (Python/Flask)
- Framework: Flask
- Libraries: Pandas, Scikit-learn
- Database: SQLite

## Project Structure

```
finsight_app/
├── frontend/          # Flutter application
│   ├── lib/
│   │   ├── models/    # Data models
│   │   ├── services/  # Business logic
│   │   ├── screens/   # UI screens
│   │   ├── widgets/   # Reusable widgets
│   │   └── main.dart
│   └── assets/        # ML model and images
└── backend/           # Python Flask API
    ├── app.py        # Main Flask application
    ├── models/       # Data models
    └── requirements.txt
```

## Getting Started

### Frontend Setup
1. Navigate to `frontend/` directory
2. Run `flutter pub get`
3. Run `flutter run`

### Backend Setup
1. Navigate to `backend/` directory
2. Install dependencies: `pip install -r requirements.txt`
3. Run Flask app: `python app.py`

## Privacy & Security

- All SMS data processing happens locally on the device
- No sensitive financial data is transmitted to servers
- ML model runs entirely on-device using TensorFlow Lite
- Backend only receives aggregated, anonymized spending data for analytics
