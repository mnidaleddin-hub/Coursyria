import requests
import json
import time

BASE_URL = "http://localhost:8000"

def test_full_auth_flow(phone):
    print(f"--- Testing Full Auth Flow for {phone} ---")
    
    # 1. Send OTP
    print(f"1. Calling /auth/send-otp for {phone} via WhatsApp...")
    send_payload = {
        "contact": phone,
        "channel": "whatsapp",
        "type": "login"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/send-otp", json=send_payload)
        print(f"   Status Code: {response.status_code}")
        print(f"   Response: {response.text}")
        
        if response.status_code != 200:
            print("   Failed to send OTP.")
            return

        print("\nOTP should be sent to your phone now.")
        print("Wait for the user to provide the code or check logs if possible.")
        
    except Exception as e:
        print(f"   Error: {e}")

if __name__ == "__main__":
    # Test with the user's number
    test_full_auth_flow("971504245008")
