#!/usr/bin/env python3
"""GitHub Notifications - Shows unread notification count"""
import json
import urllib.request
import os

# Set your GitHub token in GITHUB_TOKEN env var
TOKEN = os.environ.get('GITHUB_TOKEN', '')

def get_notifications():
    if not TOKEN:
        return None, "Set GITHUB_TOKEN env var"

    try:
        req = urllib.request.Request(
            "https://api.github.com/notifications",
            headers={
                'Authorization': f'token {TOKEN}',
                'Accept': 'application/vnd.github.v3+json'
            }
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            return data, None
    except Exception as e:
        return None, str(e)

notifications, error = get_notifications()

if error:
    print(f" ? | color=gray")
    print("---")
    print(f"Error: {error}")
else:
    count = len(notifications)
    color = 'blue' if count > 0 else 'gray'

    print(f" {count} | color={color}")
    print("---")

    if notifications:
        for notif in notifications[:10]:
            repo = notif['repository']['full_name']
            title = notif['subject']['title'][:50]
            type_ = notif['subject']['type']
            print(f"{type_}: {title}")
            print(f"  {repo}")

        if count > 10:
            print(f"...and {count - 10} more")
    else:
        print("No unread notifications")

    print("---")
    print("Open GitHub Notifications | href=https://github.com/notifications")

print("---")
print("Refresh | refresh=true")
