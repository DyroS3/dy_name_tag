-- 玩家离开时清理 state bag
AddEventHandler('playerDropped', function()
    local src = source
    local player = Player(src)
    if player and player.state and player.state.set then
        player.state:set('dy_nameTag', nil, true)
    end
end)

-- 超级标签数据库操作

local SuperTagCache = {} -- 内存缓存

-- 从数据库加载玩家数据
---@param identifier string
---@return table|nil
local function loadPlayerFromDB(identifier)
    if not identifier or identifier == '' then return nil end

    local rows = MySQL.query.await('SELECT * FROM dy_supertags WHERE identifier = ?', { identifier })
    if not rows or not rows[1] then return nil end

    ---@type table
    local r = rows[1]
    local allTitle = {}
    if r.all_titles then
        local ok, decoded = pcall(json.decode, r.all_titles)
        if ok and type(decoded) == 'table' then allTitle = decoded end
    end

    local entry = {
        playername = r.playername or '',
        color = r.color or '#FFFFFF',
        title = r.current_title or '',
        allTitle = allTitle,
    }
    SuperTagCache[identifier] = entry
    return entry
end

-- 获取或创建玩家超级标签数据
---@param identifier string
---@return table
local function getOrCreateEntry(identifier)
    if SuperTagCache[identifier] then
        return SuperTagCache[identifier]
    end

    local entry = loadPlayerFromDB(identifier)
    if entry then return entry end

    entry = { playername = '', color = '#FFFFFF', title = '', allTitle = {} }
    SuperTagCache[identifier] = entry
    return entry
end

-- 保存玩家数据到数据库
---@param identifier string
---@param entry table
local function saveToDB(identifier, entry)
    if not identifier or identifier == '' then return end
    MySQL.insert.await([[
        INSERT INTO dy_supertags (identifier, playername, current_title, color, all_titles)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            playername = VALUES(playername),
            current_title = VALUES(current_title),
            color = VALUES(color),
            all_titles = VALUES(all_titles)
    ]], { identifier, entry.playername or '', entry.title or '', entry.color or '#FFFFFF', json.encode(entry.allTitle or {}) })
end

-- 添加标签到列表（去重）
---@param entry table
---@param title string
---@return boolean 是否添加成功
local function addTitleToEntry(entry, title)
    for i = 1, #entry.allTitle do
        if entry.allTitle[i] == title then return false end
    end
    entry.allTitle[#entry.allTitle + 1] = title
    return true
end

-- 从列表移除标签
---@param entry table
---@param title string
local function removeTitleFromEntry(entry, title)
    local new = {}
    for i = 1, #entry.allTitle do
        if entry.allTitle[i] ~= title then new[#new + 1] = entry.allTitle[i] end
    end
    entry.allTitle = new
end

-- 获取玩家唯一标识
local function getIdentifier(src)
    if M and M.GetIdentifier then
        local ok, id = pcall(M.GetIdentifier, src)
        if ok and id and id ~= '' then return id end
    end
    local lic = GetPlayerIdentifierByType(src, 'license')
    if lic and lic ~= '' then return lic end
    local steam = GetPlayerIdentifierByType(src, 'steam')
    if steam and steam ~= '' then return steam end
    return nil
end

-- 构建管理端数据结构
local function buildAdminEntry(identifier)
    local e = getOrCreateEntry(identifier)
    return {
        identifier = identifier,
        title = e.title or '',
        color = e.color or '#FFFFFF',
        list = e.allTitle or {},
        count = #(e.allTitle or {}),
    }
end

-- 同步超级标签到 state bag
function SyncSuperToState(src)
    local id = getIdentifier(src)
    if not id then return end

    local e = getOrCreateEntry(id)
    if (not e.title or e.title == '') and #(e.allTitle or {}) > 0 then
        e.title = e.allTitle[1]
        saveToDB(id, e)
    end

    local player = Player(src)
    if player and player.state and player.state.set then
        local cur = player.state.dy_nameTag or {}
        cur.superTag = e.title or ''
        cur.superColor = e.color or '#FFFFFF'
        player.state:set('dy_nameTag', cur, true)
    end
end

-- 根据 identifier 查找在线玩家
local function findPlayerByIdentifier(identifier)
    local list = GetPlayers()
    for i = 1, #list do
        local s = tonumber(list[i])
        if getIdentifier(s) == identifier then
            return s
        end
    end
    return nil
end

-- 管理员权限检查
local function isAdmin(src)
    if src == 0 then return true end
    if M and M.IsAdmin then
        local ok, res = pcall(M.IsAdmin, src)
        if ok and res then return true end
    end
    return false
end

-- 管理端事件：加载玩家档案
RegisterNetEvent('dy_name_tag:adminLoadEntry', function(identifier)
    local src = source
    if not isAdmin(src) then return end
    if type(identifier) ~= 'string' or identifier == '' then return end

    SuperTagCache[identifier] = nil -- 强制刷新缓存
    loadPlayerFromDB(identifier)
    local entry = buildAdminEntry(identifier)
    TriggerClientEvent('dy_name_tag:adminEntryData', src, identifier, entry)
end)

-- 管理端事件：添加标签
RegisterNetEvent('dy_name_tag:adminAddTitle', function(identifier, title)
    local src = source
    if not isAdmin(src) then return end
    if type(identifier) ~= 'string' or identifier == '' then return end
    if type(title) ~= 'string' or title == '' then return end

    local e = getOrCreateEntry(identifier)
    addTitleToEntry(e, title)
    saveToDB(identifier, e)

    local entry = buildAdminEntry(identifier)
    TriggerClientEvent('dy_name_tag:adminEntryData', src, identifier, entry)
end)

-- 管理端事件：删除标签
RegisterNetEvent('dy_name_tag:adminRemoveTitle', function(identifier, title)
    local src = source
    if not isAdmin(src) then return end
    if type(identifier) ~= 'string' or identifier == '' then return end
    if type(title) ~= 'string' or title == '' then return end

    local e = getOrCreateEntry(identifier)
    removeTitleFromEntry(e, title)

    if e.title == title then
        e.title = e.allTitle[1] or ''
    end
    saveToDB(identifier, e)

    local entry = buildAdminEntry(identifier)
    TriggerClientEvent('dy_name_tag:adminEntryData', src, identifier, entry)
end)

-- 管理端事件：设置当前使用的标签
RegisterNetEvent('dy_name_tag:adminSetTitle', function(identifier, title)
    local src = source
    if not isAdmin(src) then return end
    if type(identifier) ~= 'string' or identifier == '' then return end
    if type(title) ~= 'string' or title == '' then return end

    local e = getOrCreateEntry(identifier)
    for i = 1, #e.allTitle do
        if e.allTitle[i] == title then
            e.title = title
            saveToDB(identifier, e)
            local entry = buildAdminEntry(identifier)
            TriggerClientEvent('dy_name_tag:adminEntryData', src, identifier, entry)
            local target = findPlayerByIdentifier(identifier)
            if target then SyncSuperToState(target) end
            return
        end
    end
end)

-- 管理端事件：设置标签颜色
RegisterNetEvent('dy_name_tag:adminSetColor', function(identifier, hex)
    local src = source
    if not isAdmin(src) then return end
    if type(identifier) ~= 'string' or identifier == '' then return end
    if type(hex) ~= 'string' or hex == '' then return end

    local e = getOrCreateEntry(identifier)
    e.color = hex
    saveToDB(identifier, e)

    local entry = buildAdminEntry(identifier)
    TriggerClientEvent('dy_name_tag:adminEntryData', src, identifier, entry)
    local target = findPlayerByIdentifier(identifier)
    if target then SyncSuperToState(target) end
end)

-- 回调：获取玩家超级标签列表
lib.callback.register('dy_name_tag:getSuperTitles', function(source)
    local id = getIdentifier(source)
    if not id then return { list = {}, selected = '', color = '#FFFFFF' } end

    local e = getOrCreateEntry(id)
    if (not e.title or e.title == '') and #(e.allTitle or {}) > 0 then
        e.title = e.allTitle[1]
        saveToDB(id, e)
    end

    return { list = e.allTitle or {}, selected = e.title or '', color = e.color or '#FFFFFF' }
end)

-- 回调：获取管理端上下文（在线玩家列表）
lib.callback.register('dy_name_tag:getAdminContext', function(source)
    local admin = isAdmin(source)
    local players = {}

    if admin then
        local list = GetPlayers()
        for i = 1, #list do
            local s = tonumber(list[i])
            local id = getIdentifier(s)
            local name
            if M and M.GetPlayerDisplayName then
                local ok, display = pcall(M.GetPlayerDisplayName, s)
                if ok and display and display ~= '' then name = display end
            end
            if not name or name == '' then
                ---@diagnostic disable-next-line: param-type-mismatch
                name = GetPlayerName(s) or tostring(s)
            end
            players[#players + 1] = { id = s, name = name, identifier = id or '' }
        end
    end

    return { isAdmin = admin, players = players }
end)

-- 玩家选择超级标签
RegisterNetEvent('dy_name_tag:setSuperTitle', function(title)
    local src = source
    if type(title) ~= 'string' or title == '' then return end

    local id = getIdentifier(src)
    if not id then return end

    local e = getOrCreateEntry(id)
    for i = 1, #e.allTitle do
        if e.allTitle[i] == title then
            e.title = title
            saveToDB(id, e)
            SyncSuperToState(src)
            return
        end
    end
end)

-- 数据迁移命令：从 title_data.json 导入数据库
-- 用法：服务端控制台执行 dy_migrate_supertags
local resourceName = GetCurrentResourceName()

RegisterCommand('dy_migrate_supertags', function(source, args, rawCommand)
    if source ~= 0 then
        print('[dy_name_tag] 此命令只能在服务端控制台执行')
        return
    end

    print('[dy_name_tag] 开始从 title_data.json 迁移数据...')

    local data = LoadResourceFile(resourceName, 'title_data.json')
    if not data or data == '' then
        print('[dy_name_tag] 未找到 title_data.json，跳过迁移')
        return
    end

    local ok, jsonData = pcall(function() return json.decode(data) end)
    if not ok or type(jsonData) ~= 'table' then
        print('[dy_name_tag] JSON 解析失败')
        return
    end

    local count = 0

    for identifier, entry in pairs(jsonData) do
        if type(identifier) == 'string' and identifier ~= '' and type(entry) == 'table' then
            local allTitle = entry.allTitle or {}
            -- 去重
            local seen, unique = {}, {}
            for i = 1, #allTitle do
                local t = allTitle[i]
                if type(t) == 'string' and t ~= '' and not seen[t] then
                    seen[t] = true
                    unique[#unique + 1] = t
                end
            end

            MySQL.insert.await([[
                INSERT INTO dy_supertags (identifier, playername, current_title, color, all_titles)
                VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    playername = VALUES(playername),
                    current_title = VALUES(current_title),
                    color = VALUES(color),
                    all_titles = VALUES(all_titles)
            ]], { identifier, entry.playername or '', entry.title or '', entry.color or '#FFFFFF', json.encode(unique) })

            SuperTagCache[identifier] = {
                playername = entry.playername or '',
                color = entry.color or '#FFFFFF',
                title = entry.title or '',
                allTitle = unique,
            }
            count = count + 1
        end
    end

    print(('[dy_name_tag] 迁移完成！%d 个玩家'):format(count))
end, true)