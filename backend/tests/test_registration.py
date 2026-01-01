import requests
import json

# Test registration endpoint
url = "http://localhost:8000/api/auth/register/"
payload = {
    "email": "testuser@example.com",
    "password": "TestPassword123!",
    "first_name": "Test",
    "last_name": "User"
}

try:
    response = requests.post(url, json=payload)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"Error: {e}")
