-- git-status.30s.lua
-- Git Status using Crossbar API

-- Helper to run shell command and get output
local function run_cmd(cmd)
    local output = crossbar.exec(cmd)
    if output then
        return output:match("^%s*(.-)%s*$") -- Trim whitespace
    end
    return ""
end

-- Check if in a git repo
local git_check = run_cmd("git rev-parse --is-inside-work-tree 2>/dev/null")
if git_check ~= "true" then
    print(" Not a repo")
    print("---")
    print("Not inside a git repository")
    print("Refresh | refresh=true")
    return
end

-- Get current branch
local branch = run_cmd("git branch --show-current")

-- Get status (porcelain)
local status = run_cmd("git status --porcelain")
local changes = 0
local lines = {}

if status ~= "" then
    for line in status:gmatch("[^
]+") do
        changes = changes + 1
        table.insert(lines, line)
    end
end

local icon = changes > 0 and "" or ""
local color = changes > 0 and "orange" or "green"

print(icon .. " " .. branch .. " | color=" .. color)
print("---")
print("Branch: " .. branch)
print("---")

if changes > 0 then
    print("Changes: " .. changes)
    print("---")
    
    local count = 0
    for _, line in ipairs(lines) do
        if count < 10 then
            print(line)
        end
        count = count + 1
    end
    
    if count > 10 then
        print("...and " .. (count - 10) .. " more files")
    end
else
    print("Working tree clean")
end

print("---")
print("Refresh | refresh=true")

