#!/usr/bin/env python3
"""Todo List - Simple todo manager"""
import json
import os

TODO_FILE = os.path.expanduser('~/.crossbar/todos.json')

def load_todos():
    try:
        if os.path.exists(TODO_FILE):
            with open(TODO_FILE, 'r') as f:
                return json.load(f)
    except:
        pass
    return []

def save_todos(todos):
    os.makedirs(os.path.dirname(TODO_FILE), exist_ok=True)
    with open(TODO_FILE, 'w') as f:
        json.dump(todos, f, indent=2)

todos = load_todos()
pending = [t for t in todos if not t.get('done', False)]
done = [t for t in todos if t.get('done', False)]

count = len(pending)
icon = '' if count == 0 else ''

print(f"{icon} {count}")
print("---")

if pending:
    print("Pending:")
    for i, todo in enumerate(pending):
        text = todo.get('text', 'Untitled')
        print(f"  {text}")
else:
    print("No pending tasks")

if done:
    print("---")
    print("Completed:")
    for todo in done[:5]:  # Show last 5
        text = todo.get('text', 'Untitled')
        print(f"  {text}")

print("---")
print(f"Total: {len(todos)} | Pending: {len(pending)} | Done: {len(done)}")
print("---")
print("Refresh | refresh=true")
