# FinSight Flutter App Setup Instructions

## Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android device or emulator for testing

## Installation

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Features

### Onboarding Flow
- Welcome screen with app benefits
- SMS permission request
- Initial SMS analysis and categorization

### Main Dashboard
- Monthly spending summary
- Category-wise spending chart
- Recent transactions list
- Quick action buttons

### Manual Expense Entry
- Add expenses manually
- Category selection
- Date picker
- Amount and merchant input

### Budget Planning
- AI-powered budget suggestions
- Budget vs spending comparison
- Category-wise budget tracking

### Spending Forecast
- 30-day spending predictions
- Trend analysis
- Daily forecast breakdown

### Savings Planner
- Goal-based savings planning
- Spending cut suggestions
- Timeline optimization

## Privacy & Security

- All SMS processing happens on-device
- No sensitive data transmitted to servers
- ML model runs locally using TensorFlow Lite
- Backend only receives aggregated spending data

## Permissions Required

- SMS Read Permission: To automatically categorize financial transactions
- Internet Permission: To communicate with backend API

## Troubleshooting

### Common Issues

1. **SMS Permission Denied**
   - Go to Settings > Apps > FinSight > Permissions
   - Enable SMS permission manually

2. **ML Model Loading Error**
   - The app will fallback to rule-based categorization
   - Check that `assets/sms_categorizer.tflite` exists

3. **Backend Connection Error**
   - Ensure Flask server is running on localhost:5000
   - Check network connectivity
   - Verify CORS settings in backend

### Development Notes

- The app uses Provider for state management
- SQLite database stores all transaction data locally
- Charts are rendered using fl_chart package
- HTTP requests use the http package for API communication
