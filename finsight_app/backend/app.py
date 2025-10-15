import joblib
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import sqlite3
import os

# --- Flask App Setup ---
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# --- Model Path ---
MODEL_PATH = 'budget_forecasting_model_v2.pkl'

try:
    BUDGET_MODEL = joblib.load(MODEL_PATH)
    print(f"✓ Budget model loaded successfully from {MODEL_PATH}")
except FileNotFoundError:
    print(f"⚠ WARNING: Model file not found at {MODEL_PATH}")
    print(f"  The /predict_budget_v2 endpoint will not work.")
    BUDGET_MODEL = None
except Exception as e:
    print(f"⚠ WARNING: Error loading model: {str(e)}")
    BUDGET_MODEL = None

# --- Model Logic (V2 - Budget Forecasting) ---
def forecast_budget_v2(principal_amount, model_params, goal_or_new_fixed_amount=0.0):
    fixed_budget_model = model_params['fixed_budget']
    variable_ratio_model = model_params['variable_ratios']
    total_avg_fixed_historical = model_params['total_avg_fixed']

    forecast = {}
    cuts_required = {}
    
    # 1. Calculate TOTAL Mandatory Commitment
    total_mandatory_commitment = total_avg_fixed_historical + goal_or_new_fixed_amount
    
    # 2. Allocate Historical Fixed Expenses and the New Goal
    for category, avg_amount in fixed_budget_model.items():
        forecast[category] = avg_amount
    
    if goal_or_new_fixed_amount > 0:
        forecast['NEW_EMI_OR_GOAL'] = round(goal_or_new_fixed_amount, 2)
        
    # 3. Calculate Budget Remaining for Variable Expenses
    variable_budget_remaining = principal_amount - total_mandatory_commitment

    # 4. Allocation or Cut Calculation
    if variable_budget_remaining >= 0:
        # A. SURPLUS SCENARIO
        warning = None
        for category, ratio in variable_ratio_model.items():
            forecast[category] = round(variable_budget_remaining * ratio, 2)
            cuts_required[category] = 0.00
    else:
        # B. SHORTFALL SCENARIO
        shortfall_amount = abs(variable_budget_remaining)
        warning = f"WARNING: Budget deficit of {shortfall_amount:,.2f} detected after mandatory allocations."
        
        total_historical_variable_ratio = sum(variable_ratio_model.values()) 
        
        for category, ratio in variable_ratio_model.items():
            forecast[category] = 0.00
            required_cut = shortfall_amount * ratio / total_historical_variable_ratio
            cuts_required[category] = round(required_cut, 2)

    # 5. Final Summary
    total_forecasted_variable_spend = sum([v for k, v in forecast.items() if k in variable_ratio_model])

    summary_output = {
        'TOTAL_PRINCIPAL': round(principal_amount, 2),
        'TOTAL_HISTORICAL_FIXED': round(total_avg_fixed_historical, 2),
        'NEW_EMI_OR_GOAL_AMOUNT': round(goal_or_new_fixed_amount, 2),
        'TOTAL_MANDATORY_COMMITMENT': round(total_mandatory_commitment, 2),
        'VARIABLE_BUDGET_REMAINING': round(variable_budget_remaining, 2),
        'TOTAL_FORECASTED_VARIABLE_SPEND': round(total_forecasted_variable_spend, 2),
        'TOTAL_FORECASTED_SPEND': round(total_mandatory_commitment + total_forecasted_variable_spend, 2),
        'WARNING': warning
    }

    return {
        'input_principal': summary_output['TOTAL_PRINCIPAL'],
        'new_fixed_goal': summary_output['NEW_EMI_OR_GOAL_AMOUNT'],
        'allocation_breakdown': {
            'fixed_historical': {k: v for k, v in forecast.items() if k in fixed_budget_model},
            'new_goal': {k: v for k, v in forecast.items() if k == 'NEW_EMI_OR_GOAL'},
            'variable_budget': {k: v for k, v in forecast.items() if k in variable_ratio_model}
        },
        'required_cuts_to_meet_goal': cuts_required,
        'summary': summary_output
    }

# --- Database Initialization ---
def init_db():
    conn = sqlite3.connect('finsight_backend.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            data_type TEXT,
            data_json TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

# --- HTML Form ---
HTML_FORM = """
<!DOCTYPE html>
<html>
<head>
    <title>FinSight Backend API</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #007bff; }
        form { background: #f4f4f4; padding: 20px; border-radius: 8px; margin: 20px 0; }
        label { display: block; margin-top: 10px; font-weight: bold; }
        input { width: 100%; padding: 8px; margin-top: 5px; border: 1px solid #ddd; border-radius: 4px; }
        button { margin-top: 20px; padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 5px; cursor: pointer; }
        button:hover { background: #0056b3; }
        .endpoint { background: #e9ecef; padding: 10px; margin: 5px 0; border-radius: 4px; }
        .method { display: inline-block; padding: 3px 8px; border-radius: 3px; font-weight: bold; margin-right: 10px; }
        .post { background: #28a745; color: white; }
        .get { background: #17a2b8; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 FinSight Backend API</h1>
        <p>Test the budget forecasting endpoint below:</p>
        
        <form method="POST" action="/predict_budget_v2">
            <h3>Budget Forecast V2</h3>
            <label for="principal_amount">Monthly Principal Amount (₹):</label>
            <input type="number" step="0.01" id="principal_amount" name="principal_amount" value="35000.00" required>
            
            <label for="goal_amount">New EMI / Savings Goal (₹):</label>
            <input type="number" step="0.01" id="goal_amount" name="goal_amount" value="0.00" required>
            
            <button type="submit">Get Forecast</button>
        </form>
        
        <hr>
        <h3>📋 Available API Endpoints</h3>
        <div class="endpoint">
            <span class="method post">POST</span>
            <strong>/predict_budget_v2</strong> - Budget forecast with goal adjustment
        </div>
        <div class="endpoint">
            <span class="method post">POST</span>
            <strong>/initial-budget</strong> - Get initial budget suggestions
        </div>
        <div class="endpoint">
            <span class="method post">POST</span>
            <strong>/forecast</strong> - Get spending forecast (30 days)
        </div>
        <div class="endpoint">
            <span class="method post">POST</span>
            <strong>/savings-plan</strong> - Get savings plan recommendations
        </div>
        <div class="endpoint">
            <span class="method get">GET</span>
            <strong>/health</strong> - Health check
        </div>
    </div>
</body>
</html>
"""

# ==================== ROUTES ====================

@app.route('/')
def index():
    return render_template_string(HTML_FORM)

@app.route('/predict_budget_v2', methods=['POST'])
def predict_budget():
    if BUDGET_MODEL is None:
        return jsonify({"error": "Budget model not loaded. Check server logs."}), 500

    try:
        if request.is_json:
            data = request.json
            principal_amount = float(data.get('principal_amount'))
            goal_amount = float(data.get('goal_amount', 0.0))
        else:
            principal_amount = float(request.form.get('principal_amount'))
            goal_amount = float(request.form.get('goal_amount', 0.0))
    except (TypeError, ValueError):
        return jsonify({"error": "Invalid input. 'principal_amount' and 'goal_amount' must be numbers."}), 400

    if principal_amount <= 0:
        return jsonify({"error": "Principal amount must be greater than zero."}), 400

    forecast_results = forecast_budget_v2(principal_amount, BUDGET_MODEL, goal_or_new_fixed_amount=goal_amount)
    return jsonify(forecast_results)

@app.route('/initial-budget', methods=['POST'])
def get_initial_budget():
    try:
        data = request.get_json()
        monthly_spending = data.get('monthly_spending', {})
        suggested_budget = {}
        
        for category, amounts in monthly_spending.items():
            if amounts:
                avg_spend = sum(amounts) / len(amounts)
                suggested_budget[category] = round(avg_spend * 1.1, 2)
            else:
                suggested_budget[category] = 0
        
        return jsonify({'suggested_budget': suggested_budget}), 200
    except Exception as e:
        print(f"ERROR in /initial-budget: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/forecast', methods=['POST'])
def get_forecast():
    try:
        print("\n" + "="*60)
        print("📊 FORECAST REQUEST RECEIVED")
        print("="*60)
        
        data = request.get_json()
        print(f"Raw request data: {data}")
        
        daily_spends = data.get('daily_spends', [])
        
        # Validate input
        if not daily_spends:
            print("❌ ERROR: No spending data provided")
            return jsonify({'error': 'No spending data provided'}), 400
        
        if not isinstance(daily_spends, list):
            print(f"❌ ERROR: daily_spends must be a list, got {type(daily_spends)}")
            return jsonify({'error': 'daily_spends must be a list'}), 400
            
        if len(daily_spends) == 0:
            print("❌ ERROR: daily_spends list is empty")
            return jsonify({'error': 'daily_spends list is empty'}), 400
        
        print(f"✓ Received {len(daily_spends)} daily spending records")
        print(f"Sample data: {daily_spends[:2]}")
        
        # Create DataFrame
        try:
            df = pd.DataFrame(daily_spends)
            print(f"✓ DataFrame created - Shape: {df.shape}, Columns: {df.columns.tolist()}")
            
            if 'date' not in df.columns or 'amount' not in df.columns:
                print(f"❌ ERROR: Missing required columns. Found: {df.columns.tolist()}")
                return jsonify({'error': 'Missing required columns: date and amount'}), 400
            
            df['date'] = pd.to_datetime(df['date'], errors='coerce')
            df['amount'] = pd.to_numeric(df['amount'], errors='coerce')
            
            # Drop invalid rows
            initial_rows = len(df)
            df = df.dropna()
            
            if df.empty:
                print("❌ ERROR: All data was invalid or empty")
                return jsonify({'error': 'All data was invalid or empty'}), 400
            
            if len(df) < initial_rows:
                print(f"⚠ Warning: Dropped {initial_rows - len(df)} invalid rows")
            
            print(f"✓ Valid records: {len(df)}")
            
        except Exception as e:
            print(f"❌ ERROR creating DataFrame: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({'error': f'Failed to process data: {str(e)}'}), 400
        
        # Calculate forecast
        avg_daily_spend = df['amount'].mean()
        print(f"✓ Average daily spend: ₹{avg_daily_spend:.2f}")
        
        forecasted_spends = []
        start_date = datetime.now().date()
        
        for i in range(30):
            forecast_date = start_date + timedelta(days=i)
            variation = np.random.uniform(0.8, 1.2)
            forecasted_amount = avg_daily_spend * variation
            forecasted_spends.append({
                'date': forecast_date.strftime('%Y-%m-%d'),
                'amount': round(forecasted_amount, 2)
            })
        
        print(f"✓ SUCCESS: Generated forecast for 30 days")
        print("="*60 + "\n")
        
        return jsonify({'forecasted_spends': forecasted_spends}), 200
        
    except Exception as e:
        print(f"❌ UNHANDLED ERROR in /forecast: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Internal server error: {str(e)}'}), 500

@app.route('/savings-plan', methods=['POST'])
def get_savings_plan():
    try:
        data = request.get_json()
        goal_amount = float(data.get('goal_amount', 0))
        timeline_months = int(data.get('timeline_months', 1))
        average_spending = data.get('average_spending', {})
        
        if goal_amount <= 0 or timeline_months <= 0:
            return jsonify({'error': 'Invalid goal amount or timeline'}), 400
        
        required_monthly_savings = goal_amount / timeline_months
        
        discretionary_categories = ['Shopping', 'Entertainment', 'Food & Dining', 'Gifts']
        
        total_discretionary = sum(
            amount for category, amount in average_spending.items()
            if category in discretionary_categories
        )
        
        plan_possible = total_discretionary >= required_monthly_savings
        suggested_cuts = {}
        monthly_savings_achieved = 0
        
        if plan_possible:
            discretionary_spending = [
                (category, amount) for category, amount in average_spending.items()
                if category in discretionary_categories and amount > 0
            ]
            discretionary_spending.sort(key=lambda x: x[1], reverse=True)
            
            remaining_savings_needed = required_monthly_savings
            for category, amount in discretionary_spending:
                if remaining_savings_needed <= 0:
                    break
                
                if category == discretionary_spending[0][0]:
                    cut_percentage = 0.4
                elif len(discretionary_spending) > 1 and category == discretionary_spending[1][0]:
                    cut_percentage = 0.3
                else:
                    cut_percentage = 0.2
                
                suggested_cut = amount * cut_percentage
                suggested_cuts[category] = round(suggested_cut, 2)
                monthly_savings_achieved += suggested_cut
                remaining_savings_needed -= suggested_cut
        
        return jsonify({
            'plan_possible': plan_possible,
            'suggested_cuts': suggested_cuts,
            'monthly_savings_achieved': round(monthly_savings_achieved, 2)
        }), 200
    except Exception as e:
        print(f"ERROR in /savings-plan: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    model_status = "loaded" if BUDGET_MODEL is not None else "not_loaded"
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'budget_model_status': model_status
    }), 200

# ==================== MAIN ====================
if __name__ == '__main__':
    init_db()
    print("\n" + "="*70)
    print("  🚀 FinSight Backend Server Starting...")
    print("="*70)
    print("\n📋 Available API Endpoints:")
    print("   • POST   /predict_budget_v2   - Budget forecast with goal adjustment")
    print("   • POST   /initial-budget       - Get initial budget suggestions")
    print("   • POST   /forecast             - Get spending forecast (30 days)")
    print("   • POST   /savings-plan         - Get savings plan recommendations")
    print("   • GET    /health               - Health check")
    print("   • GET    /                     - Test page (browser)")
    print("\n" + "="*70)
    print(f"  🌐 Server running at: http://0.0.0.0:5000")
    print(f"  📱 For Flutter app, use: http://YOUR_IP_ADDRESS:5000")
    print("="*70 + "\n")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
