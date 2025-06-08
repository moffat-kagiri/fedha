import requests
import json

# Test basic loan calculation
data = {
    "principal": 100000.00,
    "annual_rate": 5.5,
    "term_years": 30,
    "interest_type": "reducing_balance",
    "payment_frequency": "monthly"
}

try:
    response = requests.post("http://127.0.0.1:8000/api/calculators/loan/", json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
