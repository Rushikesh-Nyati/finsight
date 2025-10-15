#!/usr/bin/env python3
"""
Test script for FinSight Backend API
Run this after starting the Flask server to test all endpoints
"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = 'http://localhost:5000'

def test_health():
    """Test health endpoint"""
    print("Testing health endpoint...")
    response = requests.get(f'{BASE_URL}/health')
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_initial_budget():
    """Test initial budget endpoint"""
    print("Testing initial budget endpoint...")
    data = {
        "monthly_spending": {
            "Food & Dining": [12000, 13500, 12800],
            "Shopping": [25000, 15000, 32000],
            "Transportation": [8000, 7500, 8200],
            "Bills & Utilities": [15000, 15000, 15000],
            "Groceries": [10000, 9500, 10500]
        }
    }
    response = requests.post(f'{BASE_URL}/initial-budget', json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_forecast():
    """Test forecast endpoint"""
    print("Testing forecast endpoint...")
    
    # Generate sample daily spending data
    daily_spends = []
    base_date = datetime.now() - timedelta(days=30)
    
    for i in range(30):
        date = base_date + timedelta(days=i)
        amount = 1000 + (i % 7) * 200  # Varying amounts
        daily_spends.append({
            "date": date.strftime('%Y-%m-%d'),
            "amount": amount
        })
    
    data = {"daily_spends": daily_spends}
    response = requests.post(f'{BASE_URL}/forecast', json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_savings_plan():
    """Test savings plan endpoint"""
    print("Testing savings plan endpoint...")
    data = {
        "goal_amount": 80000,
        "timeline_months": 6,
        "average_spending": {
            "Food & Dining": 13000,
            "Transportation": 8000,
            "Shopping": 25000,
            "Bills & Utilities": 15000,
            "Groceries": 10000,
            "Entertainment": 12000,
            "Health & Wellness": 5000,
            "Gifts": 3000
        }
    }
    response = requests.post(f'{BASE_URL}/savings-plan', json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def main():
    print("FinSight Backend API Test")
    print("=" * 40)
    print()
    
    try:
        test_health()
        test_initial_budget()
        test_forecast()
        test_savings_plan()
        print("All tests completed successfully!")
        
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to the server.")
        print("Make sure the Flask server is running on localhost:5000")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
