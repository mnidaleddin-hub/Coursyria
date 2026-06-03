import httpx
import json

url = "https://coursyria-api.onrender.com/auth/verify-email-otp"
payload = {
    "contact": "trae_test_final@example.com",
    "otp": "429527",
    "device_id": "test_device",
    "full_name": "Trae Final Test",
    "password": "password123"
}

try:
    response = httpx.post(url, json=payload, timeout=30.0)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
