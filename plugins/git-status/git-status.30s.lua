-- git-status.30s.lua
-- Git Status using Crossbar CLI

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function env_bool(name, default)
    local value = env(name, default and 'true' or 'false')
    if value == nil then
        return default
    end
    value = tostring(value):lower()
    return value == 'true' or value == '1' or value == 'yes' or value == 'on'
end

local function env_num(name, default)
    local value = env(name, tostring(default))
    local num = tonumber(value)
    if num == nil then
        return default
    end
    return num
end

local function trim(value)
    if value == nil then return '' end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local is_mobile = crossbar.isMobile()
if is_mobile then
    print('git N/A | color=gray')
    print('---')
    print('Git status is desktop-only')
    print('---')
    print('Refresh | refresh=true')
    return
end

local max_files = env_num('GIT_MAX_FILES', 10)
if max_files < 1 then max_files = 1 end
if max_files > 200 then max_files = 200 end
local show_files = env_bool('GIT_SHOW_FILES', true)

local git_check = trim(crossbar.exec('git rev-parse --is-inside-work-tree 2>/dev/null'))
if git_check ~= 'true' then
    print('git Not a repo | color=gray')
    print('---')
    print('Not inside a git repository')
    print('---')
    print('Refresh | refresh=true')
    return
end

local branch = trim(crossbar.exec('git branch --show-current'))
if branch == '' then branch = 'detached' end

local status = crossbar.exec('git status --porcelain')
local changes = 0
local lines = {}

for line in (status or ''):gmatch('[^\n]+') do
    changes = changes + 1
    table.insert(lines, line)
end

local color = changes > 0 and 'orange' or 'green'

print('git ' .. branch .. ' | color=' .. color)
print('---')
print('Branch: ' .. branch)

if changes > 0 then
    print('Changes: ' .. tostring(changes))
    if show_files then
        print('---')
        local count = 0
        for _, line in ipairs(lines) do
            if count < max_files then
                print(line)
            end
            count = count + 1
        end
        if count > max_files then
            print('...and ' .. tostring(count - max_files) .. ' more files')
        end
    end
else
    print('Working tree clean')
end

print('---')
print('Refresh | refresh=true')
