def test_validation(contact):
    print(f"Testing contact: '{contact}'")
    
    # Simulate the logic in auth.py
    try:
        if contact.startswith("@"):
            print("  Result: Telegram Username (OK)")
            return True
        else:
            # 1. Basic cleaning
            clean_contact = contact.replace('+', '').replace(' ', '').replace('-', '')
            if clean_contact.startswith('00'):
                clean_contact = clean_contact[2:]
            
            # 2. Check if it's all digits
            if not clean_contact.isdigit():
                print("  Result: Error - Not all digits")
                return False
            
            # 3. Validation of subscriber part (last 9 digits)
            if len(clean_contact) < 10:
                print("  Result: Error - Too short")
                return False
            
            subscriber_part = clean_contact[-9:]
            country_part = clean_contact[:-9]
            
            # RULE: The part before the 9 digits must not end with 0 (e.g., 9710... is invalid)
            if len(clean_contact) > 9 and clean_contact[-10] == '0':
                print(f"  Result: Error - Invalid zero detected at position -10: {clean_contact}")
                return False
            
            if len(subscriber_part) != 9:
                print(f"  Result: Error - Subscriber part is not 9 digits: {subscriber_part}")
                return False
            
            print(f"  Result: OK - Country: {country_part}, Subscriber: {subscriber_part}")
            return True
    except Exception as e:
        print(f"  Result: Exception - {e}")
        return False

# Test cases
test_cases = [
    "971504245008",      # Valid UAE
    "963930111876",      # Valid Syria
    "+971504245008",     # Valid with +
    "00971504245008",    # Valid with 00
    "9710504245008",     # SHOULD BE INVALID (0 after country code)
    "9630930111876",     # SHOULD BE INVALID (0 after country code)
    "97112345678",       # Invalid (too short)
    "9711234567890",     # Valid (9 digits are 234567890, country 9711)
    "@username",         # Valid Telegram
]

for tc in test_cases:
    test_validation(tc)
    print("-" * 20)
