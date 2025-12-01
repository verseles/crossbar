#!/usr/bin/env python3
"""Daily Quote - Shows an inspirational quote"""
import json
import urllib.request
import random

QUOTES = [
    {"text": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
    {"text": "Innovation distinguishes between a leader and a follower.", "author": "Steve Jobs"},
    {"text": "Stay hungry, stay foolish.", "author": "Steve Jobs"},
    {"text": "Code is like humor. When you have to explain it, it's bad.", "author": "Cory House"},
    {"text": "First, solve the problem. Then, write the code.", "author": "John Johnson"},
    {"text": "Simplicity is the soul of efficiency.", "author": "Austin Freeman"},
    {"text": "Make it work, make it right, make it fast.", "author": "Kent Beck"},
    {"text": "Talk is cheap. Show me the code.", "author": "Linus Torvalds"},
    {"text": "Any fool can write code that a computer can understand.", "author": "Martin Fowler"},
    {"text": "The best error message is the one that never shows up.", "author": "Thomas Fuchs"},
]

def get_quote():
    try:
        url = "https://api.quotable.io/random"
        with urllib.request.urlopen(url, timeout=3) as response:
            data = json.loads(response.read().decode())
            return {"text": data['content'], "author": data['author']}
    except:
        return random.choice(QUOTES)

quote = get_quote()
text = quote['text']
author = quote['author']

# Truncate for display
display_text = text[:40] + "..." if len(text) > 40 else text

print(f" {display_text}")
print("---")
print(f'"{text}"')
print(f"  - {author}")
print("---")
print("New Quote | refresh=true")
