import requests
import json
import os

key = "E940D348B900084308873B43B26B51"
url = "https://api.isekaichat.com/instance/fetchInstances"

headers = {
    "apikey": key,
    "Content-Type": "application/json"
}

print(f"Testing URL: {url}")
print(f"Using Header: apikey: {key}")

try:
    response = requests.get(url, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Connection Error: {e}")
