-- submenu-demo.1m.lua
-- Demonstrates hierarchical submenu support using BitBar/Argos -- prefix notation.
-- This plugin showcases nested menus up to 3 levels deep.

-- Main output line
print("Submenus Demo")
print("---")

-- Simple flat items (no submenu)
print("Flat Item 1")
print("Flat Item 2")
print("---")

-- Single-level submenu using -- prefix
print("File Actions")
print("--Open | bash=xdg-open .")
print("--Save")
print("--Close")
print("---")

-- Multi-level nested submenu
print("Settings")
print("--Display")
print("----Brightness")
print("------Low")
print("------Medium")
print("------High")
print("----Resolution")
print("------1080p")
print("------1440p")
print("------4K")
print("--Audio")
print("----Volume")
print("------25%")
print("------50%")
print("------75%")
print("------100%")
print("----Output Device")
print("------Speakers")
print("------Headphones")
print("--Network")
print("----WiFi")
print("----Ethernet")
print("---")

-- Items with attributes in submenus
print("Quick Links")
print("--GitHub | href=https://github.com")
print("--Google | href=https://google.com | color=blue")
print("--Terminal | bash=x-terminal-emulator")
print("---")

-- Mixed content
print("More Options")
print("--Option A")
print("--Option B")
print("Another Flat Item")
