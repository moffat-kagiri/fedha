import requests
import hashlib
import pytest

BASE_URL = "http://localhost:8000/api"

def test_profile_creation():
    # Generate test data
    profile_id = "biz_test123"
    pin = "1234"
    pin_hash = hashlib.sha256(pin.encode()).hexdigest()

    # Create profile via API
    response = requests.post(
        f"{BASE_URL}/profiles/",
        json={
            "id": profile_id,
            "is_business": True,
            "pin_hash": pin_hash
        }
    )
    
    assert response.status_code == 201
    assert response.json()["id"] == profile_id

def test_profile_login():
    # First create a profile
    profile_id = "personal_test456"
    pin = "5678"
    
    # Attempt login with correct PIN
    login_response = requests.post(
        f"{BASE_URL}/login/",
        json={"profile_id": profile_id, "pin": pin}
    )
    assert login_response.status_code == 200
    assert "token" in login_response.json()

    # Test wrong PIN
    failed_login = requests.post(
        f"{BASE_URL}/login/",
        json={"profile_id": profile_id, "pin": "wrong"}
    )
    assert failed_login.status_code == 401