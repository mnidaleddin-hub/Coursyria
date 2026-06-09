import requests

# WhatsApp Configuration
url_wa = "https://7107.api.greenapi.com/waInstance7107621915/sendMessage/671698dabcf043ed84bc4726b52d242f6035b4f0cc3b4a4f81"
# Telegram Configuration
url_tg = "https://4100.api.green-api.com/waInstance4100621926/sendMessage/a09261acfb484f7788db3fe9ec7d41cc55db1340d07048a5a6"

phone = "971504245008"
otp = "123456"

headers = {
    'Content-Type': 'application/json'
}

print(f"--- Testing for phone: {phone} ---\n")

# WhatsApp Test (Removed customPreview to avoid 400 error)
payload_wa = {
    "chatId": f"{phone}@c.us",
    "message": f"رمز التحقق الخاص بك في كورسيريا هو: {otp}"
}
print("Testing WhatsApp...")
response_wa = requests.post(url_wa, json=payload_wa, headers=headers)
print("WhatsApp Response:")
print(response_wa.text.encode('utf8'))

print("\n" + "="*30 + "\n")

# Telegram Test (Kept customPreview as it worked)
payload_tg = {
    "chatId": f"{phone}@c.us",
    "message": f"رمز التحقق الخاص بك في كورسيريا هو: {otp}",
    "customPreview": {}
}
print("Testing Telegram...")
response_tg = requests.post(url_tg, json=payload_tg, headers=headers)
print("Telegram Response:")
print(response_tg.text.encode('utf8'))
