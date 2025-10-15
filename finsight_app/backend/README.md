# FinSight Backend Setup Instructions

## Prerequisites
- Python 3.8 or higher
- pip package manager

## Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a virtual environment (recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the Flask server:
   ```bash
   python app.py
   ```

The server will start on http://localhost:5000

## API Endpoints

### POST /initial-budget
Generates budget suggestions based on historical spending data.

**Request Body:**
```json
{
  "monthly_spending": {
    "Food & Dining": [12000, 13500, 12800],
    "Shopping": [25000, 15000, 32000]
  }
}
```

**Response:**
```json
{
  "suggested_budget": {
    "Food & Dining": 14000,
    "Shopping": 26000
  }
}
```

### POST /forecast
Generates spending forecasts for the next 30 days.

**Request Body:**
```json
{
  "daily_spends": [
    {"date": "2023-10-01", "amount": 1500},
    {"date": "2023-10-02", "amount": 800}
  ]
}
```

**Response:**
```json
{
  "forecasted_spends": [
    {"date": "2023-11-01", "amount": 1600},
    {"date": "2023-11-02", "amount": 950}
  ]
}
```

### POST /savings-plan
Creates a savings plan based on goals and spending patterns.

**Request Body:**
```json
{
  "goal_amount": 80000,
  "timeline_months": 6,
  "average_spending": {
    "Food & Dining": 13000,
    "Transportation": 8000,
    "Shopping": 25000
  }
}
```

**Response:**
```json
{
  "plan_possible": true,
  "suggested_cuts": {
    "Shopping": 8000,
    "Entertainment": 4000,
    "Food & Dining": 1333
  },
  "monthly_savings_achieved": 13333
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2023-10-01T12:00:00"
}
```
