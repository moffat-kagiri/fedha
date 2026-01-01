import requests
import json

# Use the JWT token from previous registration
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzY3ODk4NzI5LCJpYXQiOjE3NjcyOTM5MjksImp0aSI6ImI5OTZkNGQwODZkNjRjNDM5MjcxNjljNmZkZWE5YjAxIiwidXNlcl9pZCI6ImViOTc5YjNlLTRlZmEtNGM2MS05MGI4LWM4YTU3NjkzNGE4YSJ9._INgYb0HpT3mUkU9t7SJIEb49fMdFvSmiBomZ3mCzE"

headers = {
    "Authorization": f"Bearer {token}"
}

try:
    response = requests.get("http://localhost:8000/api/health/", headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"Error: {e}")
