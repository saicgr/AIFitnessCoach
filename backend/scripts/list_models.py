#!/usr/bin/env python3
import os
from pathlib import Path
from dotenv import load_dotenv
from google import genai

env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

print("Available Gemini Models:\n")
for model in client.models.list():
    name = model.name
    if "flash" in name.lower() or "pro" in name.lower():
        print(f"  {name}")
