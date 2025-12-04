---@diagnostic disable: redundant-return-value

-- 性能优化：零内存分配绘制

-- 基础状态变量
local nameThread = false  -- 控制绘制线程是否在运行
local myNameShow = true   -- 是否显示自己的名字
local namesVisible = true -- 是否整体显示所有玩家名字

local inHideZone = false  -- 本地玩家是否处于任意 HideZone
local hideZoneCount = 0   -- 当前叠加进入的 HideZone 数量

-- 动态渲染缓存（按需创建，永久复用）
local renderCache = {}  -- 动态渲染槽位
local renderCount = 0   -- 当前活跃槽位数
local boneCache = {}    -- ped -> boneIndex 缓存

-- 缓存的配置值（在 InitDisplayConfig 中初始化）
local CFG_SCALE = 1.2
local CFG_FONT = 42
local CFG_BASE_TEXT_SCALE = 0.35
local CFG_STREAM_DISTANCE = 20
local HEAD_OFFSET_Z = 0.9
local STREAMER_BUSY_MS = 1500
local STREAMER_IDLE_MS = 2000

-- 缓存的位置配置
local POS_NAME = { 0, -0.010 }
local POS_JOB = { 0, -0.035 }
local POS_VIP = { 0, -0.060 }
local POS_SUPER = { 0, -0.085 }

-- 缓存的默认颜色
local COLOR_NAME = { 255, 255, 255 }
local COLOR_JOB = { 255, 255, 255 }

-- 预构建的职业颜色索引（标准化 job 名后匹配）
local normalizedJobColorLookup = nil

-- 获取或创建渲染槽位（动态扩展，一旦创建永久复用）
---@param index number
---@return table
local function getOrCreateSlot(index)
    local slot = renderCache[index]
    if not slot then
        slot = {
            ped = 0,
            boneIndex = 0,
            lineCount = 0,
            lines = {
                { text = "", r = 255, g = 255, b = 255, a = 255, x = 0, y = 0, scale = 0.35 },
                { text = "", r = 255, g = 255, b = 255, a = 255, x = 0, y = 0, scale = 0.35 },
                { text = "", r = 255, g = 255, b = 255, a = 255, x = 0, y = 0, scale = 0.35 },
                { text = "", r = 255, g = 255, b = 255, a = 255, x = 0, y = 0, scale = 0.35 },
            }
        }
        renderCache[index] = slot
    end
    return slot
end

-- 辅助函数

-- 获取缓存的骨骼索引（避免每帧调用 GetPedBoneIndex）
---@param ped number
---@return number
local function getCachedBoneIndex(ped)
    local cached = boneCache[ped]
    if cached then return cached end
    local idx = GetPedBoneIndex(ped, 31086)
    boneCache[ped] = idx
    return idx
end

-- 将 "RRGGBB" 或 "AARRGGBB" 形式的十六进制颜色字符串转换为 r, g, b
---@param hex string|nil
---@return number, number, number
local function HexToRGBValues(hex)
    if not hex or type(hex) ~= 'string' then return 255, 255, 255 end
    hex = hex:gsub('#', '')

    local len = #hex
    if len == 8 then
        hex = hex:sub(3)
    end

    if #hex ~= 6 then return 255, 255, 255 end

    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255

    return r, g, b
end

-- 设置文本行的颜色（直接写入预分配的 line 表）
---@param line table
---@param hexColor string|nil
---@param defaultR number
---@param defaultG number
---@param defaultB number
local function setLineColor(line, hexColor, defaultR, defaultG, defaultB)
    if hexColor then
        line.r, line.g, line.b = HexToRGBValues(hexColor)
    else
        line.r, line.g, line.b = defaultR, defaultG, defaultB
    end
end

-- 规范化职业名: 去除 &#xxxx; 形式的特殊符号以及不可见字符
---@param jobName string|nil
---@return string|nil
local function normalizeJobColorKey(jobName)
    if type(jobName) ~= 'string' or jobName == '' then return nil end
    local sanitized = jobName:gsub('&#%d+;', '')
    sanitized = sanitized:gsub('[^%w_%-]', '')
    sanitized = sanitized:lower()
    if sanitized == '' then return nil end
    return sanitized
end

-- 根据 Config.JobColors 重建标准化索引, 方便回退匹配
local function rebuildNormalizedJobColors()
    if not Config or not Config.JobColors then
        normalizedJobColorLookup = nil
        return
    end

    normalizedJobColorLookup = {}
    for jobKey, color in pairs(Config.JobColors) do
        if type(jobKey) == 'string' and color ~= nil then
            local normalizedKey = normalizeJobColorKey(jobKey)
            if normalizedKey and normalizedJobColorLookup[normalizedKey] == nil then
                normalizedJobColorLookup[normalizedKey] = color
            end
        end
    end
end

-- 从状态包中获取玩家信息（返回所有需要的数据）
---@param player number
---@return table|nil
local function getPlayerStateInfo(player)
    local serverId = GetPlayerServerId(player)
    local p = serverId and Player(serverId) or nil
    local info = p and p.state and p.state.dy_nameTag or nil
    return info, serverId
end

-- 使用 ox_lib 的 lib.zones.sphere 基于 Config.HideZone 创建隐藏区域
-- 以本地玩家为观察者：当玩家处于任一隐藏区域时，不渲染任何头顶名字
local function setupHideZones()
    if not Config.HideZone or #Config.HideZone == 0 then return end

    for i = 1, #Config.HideZone do
        local cfg = Config.HideZone[i]
        if cfg.pos and cfg.radius then
            lib.zones.sphere({
                coords = cfg.pos,
                radius = cfg.radius,
                debug = Config.Debug,
                onEnter = function()
                    hideZoneCount = hideZoneCount + 1
                    inHideZone = hideZoneCount > 0
                end,
                onExit = function()
                    hideZoneCount = math.max(hideZoneCount - 1, 0)
                    inHideZone = hideZoneCount > 0
                end,
            })
        end
    end
end

-- 初始化配置缓存（从 Config 读取）
local function initLocalConfig()
    local ds = Config.DisPlaySetting and Config.DisPlaySetting.default
    if ds then
        CFG_SCALE = ds.scale or 1.2
        CFG_FONT = ds.fontId or 42

        local posCfg = ds.pos
        if posCfg then
            if posCfg.nameTitle then POS_NAME[1], POS_NAME[2] = posCfg.nameTitle[1], posCfg.nameTitle[2] end
            if posCfg.jobTitle then POS_JOB[1], POS_JOB[2] = posCfg.jobTitle[1], posCfg.jobTitle[2] end
            if posCfg.vipTitle then POS_VIP[1], POS_VIP[2] = posCfg.vipTitle[1], posCfg.vipTitle[2] end
            if posCfg.superTitle then POS_SUPER[1], POS_SUPER[2] = posCfg.superTitle[1], posCfg.superTitle[2] end
        end

        local colorCfg = ds.color
        if colorCfg then
            if colorCfg.nameTitle then
                COLOR_NAME[1] = colorCfg.nameTitle.r or 255
                COLOR_NAME[2] = colorCfg.nameTitle.g or 255
                COLOR_NAME[3] = colorCfg.nameTitle.b or 255
            end
            if colorCfg.jobTitle then
                COLOR_JOB[1] = colorCfg.jobTitle.r or 255
                COLOR_JOB[2] = colorCfg.jobTitle.g or 255
                COLOR_JOB[3] = colorCfg.jobTitle.b or 255
            end
        end
    end

    CFG_STREAM_DISTANCE = Config.StreamDistance or 20
    local r = Config.Render or {}
    HEAD_OFFSET_Z = r.HeadOffsetZ or HEAD_OFFSET_Z
    STREAMER_BUSY_MS = r.StreamerBusyMs or STREAMER_BUSY_MS
    STREAMER_IDLE_MS = r.StreamerIdleMs or STREAMER_IDLE_MS

    -- 同步到 shared 模块
    InitDisplayConfig()

    rebuildNormalizedJobColors()
end

-- 绘制线程
local function drawNames()
    nameThread = true
    local baseScale = CFG_BASE_TEXT_SCALE * CFG_SCALE

    while renderCount > 0 do
        for i = 1, renderCount do
            local slot = renderCache[i]
            local ec = GetEntityCoords(slot.ped)
            local x, y, z = ec.x, ec.y, ec.z + HEAD_OFFSET_Z
            local lines = slot.lines
            local lineCount = slot.lineCount
            DrawText3DOptimized(x, y, z, lines, lineCount, baseScale, 255)
        end
        Wait(0)
    end

    nameThread = false
end

-- 主循环：预计算显示数据写入缓存
local function playerStreamer()
    local newPlayerIcon = Config.NewPlayerIcon
    local jobColors = Config.JobColors
    local streamDist = CFG_STREAM_DISTANCE
    local streamDist2 = streamDist * streamDist

    while namesVisible do
        local slotIndex = 0
        local myPed = cache.ped
        local myCoords = GetEntityCoords(myPed)
        local myId = cache.playerId

        -- 遍历所有在线玩家
        for _, player in pairs(GetActivePlayers()) do
            local playerPed = GetPlayerPed(player)

            -- 自己是否显示名字 & 其他玩家
            if ((player == myId and myNameShow) or player ~= myId) and DoesEntityExist(playerPed) then
                local pc = GetEntityCoords(playerPed)
                local dx = myCoords.x - pc.x
                local dy = myCoords.y - pc.y
                local dz = myCoords.z - pc.z
                local dist2 = dx * dx + dy * dy + dz * dz

                if dist2 <= streamDist2 then
                    local info, serverId = getPlayerStateInfo(player)
                    if serverId then
                        slotIndex = slotIndex + 1
                        local slot = getOrCreateSlot(slotIndex)

                        -- 设置基础数据
                        slot.ped = playerPed
                        slot.boneIndex = getCachedBoneIndex(playerPed)

                        -- 预计算所有文本行
                        local lineIdx = 0
                        local lines = slot.lines

                        -- 获取玩家状态数据
                        local displayName = (info and info.displayName and info.displayName ~= '') and info.displayName or GetPlayerName(player) or tostring(player)
                        local jobTitle = info and info.jobTitle or ''
                        local jobName = info and info.jobName or nil
                        local isNew = info and info.isNew or false
                        local vipTag = info and info.vipTag or ''
                        local vipColor = info and info.vipColor or nil
                        local superTag = info and info.superTag or ''
                        local superColor = info and info.superColor or nil

                        -- 第1行：超级标签（如果有）
                        if superTag ~= '' then
                            lineIdx = lineIdx + 1
                            local line = lines[lineIdx]
                            line.text = superTag
                            line.x, line.y = POS_SUPER[1], POS_SUPER[2]
                            setLineColor(line, superColor, COLOR_NAME[1], COLOR_NAME[2], COLOR_NAME[3])
                        end

                        -- 第2行：VIP 标签（如果有）
                        if vipTag ~= '' then
                            lineIdx = lineIdx + 1
                            local line = lines[lineIdx]
                            line.text = vipTag
                            line.x, line.y = POS_VIP[1], POS_VIP[2]
                            setLineColor(line, vipColor, COLOR_NAME[1], COLOR_NAME[2], COLOR_NAME[3])
                        end

                        -- 第3行：职业-职称（如果有）
                        if jobTitle ~= '' then
                            lineIdx = lineIdx + 1
                            local line = lines[lineIdx]
                            line.text = jobTitle
                            line.x, line.y = POS_JOB[1], POS_JOB[2]
                            local jobHex
                            if jobName and jobColors then
                                jobHex = jobColors[jobName]
                                if not jobHex and normalizedJobColorLookup then
                                    local normalizedKey = normalizeJobColorKey(jobName)
                                    if normalizedKey then
                                        jobHex = normalizedJobColorLookup[normalizedKey]
                                    end
                                end
                            end
                            setLineColor(line, jobHex, COLOR_JOB[1], COLOR_JOB[2], COLOR_JOB[3])
                        end

                        -- 第4行：名字（始终显示）
                        lineIdx = lineIdx + 1
                        local nameLine = lines[lineIdx]
                        local nameText = ('[ID: %s] %s'):format(serverId, displayName)
                        if isNew and newPlayerIcon then
                            nameText = ('%s %s'):format(newPlayerIcon, nameText)
                        end
                        nameLine.text = nameText
                        nameLine.x, nameLine.y = POS_NAME[1], POS_NAME[2]
                        nameLine.r, nameLine.g, nameLine.b = COLOR_NAME[1], COLOR_NAME[2], COLOR_NAME[3]

                        slot.lineCount = lineIdx
                    end
                end
            end
        end

        -- 更新全局渲染计数
        renderCount = inHideZone and 0 or slotIndex

        -- 清理无效的骨骼缓存
        for ped in pairs(boneCache) do
            if not DoesEntityExist(ped) then
                boneCache[ped] = nil
            end
        end

        -- 按需启动渲染线程（仅在需要时运行）
        if renderCount > 0 and not nameThread then
            CreateThread(drawNames)
        end

        -- 自适应等待时间
        Wait(renderCount > 0 and STREAMER_BUSY_MS or STREAMER_IDLE_MS)
    end

    -- 关闭展示后清空
    renderCount = 0
end

-- NUI 是否打开的状态标记（避免重复创建与焦点锁定）
local isNuiOpen = false

-- 控制是否渲染所有玩家头顶名字（开启/关闭时启动或停止渲染线程）
local function setNamesVisible(enabled)
    enabled = enabled and true or false
    if namesVisible == enabled then return end
    namesVisible = enabled
    if enabled then
        CreateThread(playerStreamer)
    else
        renderCount = 0
    end
end

-- 打开统一的 NameTag NUI（玩家端 + 管理端都走这里）
-- 会主动从服务端拉取超级标签列表与管理员上下文
local function openNameTagUI()
    if isNuiOpen then return end
    isNuiOpen = true
    SetNuiFocus(true, true)
    local hasSuper = false      -- 玩家是否拥有超级标签
    local superMeta            -- 从服务端获取的超级标签列表与当前选中
    local isAdmin = false      -- 是否具有管理权限（由服务端 bridge 判定）
    local adminPayload         -- 管理端额外数据（例如在线玩家列表）

    if cache and cache.playerId then
        local info = select(1, getPlayerStateInfo(cache.playerId))
        if info and type(info.superTag) == 'string' and info.superTag ~= '' then
            hasSuper = true
        end
    end

    if lib and lib.callback and lib.callback.await then
        -- 先获取自己的超级标签列表与当前选中
        local ok, data = pcall(function()
            return lib.callback.await('dy_name_tag:getSuperTitles', false)
        end)
        if ok and data then
            superMeta = {
                list = data.list or {},
                selected = data.selected or '',
                color = data.color or '#FFFFFF',
            }
            if (not hasSuper) and superMeta.selected ~= '' then
                hasSuper = true
            end
        end

        -- 再获取管理端上下文（是否为管理员 + 在线玩家列表）
        local ok2, adminCtx = pcall(function()
            return lib.callback.await('dy_name_tag:getAdminContext', false)
        end)
        if ok2 and adminCtx then
            isAdmin = adminCtx.isAdmin and true or false
            if isAdmin then
                adminPayload = {
                    players = adminCtx.players or {},
                }
            end
        end
    end

    SendNUIMessage({
        type = 'open',
        mode = 'player',
        payload = {
            showAllHeadtags = namesVisible,
            showSelfHeadtag = myNameShow,
            hasSuperTag = hasSuper,
            superTagMeta = superMeta,
            isAdmin = isAdmin,
            admin = adminPayload,
        }
    })
end

local function closeNameTagUI()
    if not isNuiOpen then return end
    isNuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

RegisterNUICallback('toggle_global', function(data, cb)
    setNamesVisible(data and data.value)
    if cb then cb({ ok = true }) end
end)

-- 管理端：根据 identifier 加载/刷新某个玩家的超级标签档案
RegisterNUICallback('admin_load_entry', function(data, cb)
    local identifier = data and data.identifier
    if type(identifier) == 'string' and identifier ~= '' then
        TriggerServerEvent('dy_name_tag:adminLoadEntry', identifier)
    end
    if cb then cb({ ok = true }) end
end)

-- 管理端：为指定 identifier 添加新的超级标签
RegisterNUICallback('admin_add_title', function(data, cb)
    local identifier = data and data.identifier
    local title = data and data.title
    if type(identifier) == 'string' and identifier ~= '' and type(title) == 'string' and title ~= '' then
        TriggerServerEvent('dy_name_tag:adminAddTitle', identifier, title)
    end
    if cb then cb({ ok = true }) end
end)

-- 管理端：为指定 identifier 移除某个超级标签
RegisterNUICallback('admin_remove_title', function(data, cb)
    local identifier = data and data.identifier
    local title = data and data.title
    if type(identifier) == 'string' and identifier ~= '' and type(title) == 'string' and title ~= '' then
        TriggerServerEvent('dy_name_tag:adminRemoveTitle', identifier, title)
    end
    if cb then cb({ ok = true }) end
end)

-- 管理端：将某个标签设为当前选中项
RegisterNUICallback('admin_set_title', function(data, cb)
    local identifier = data and data.identifier
    local title = data and data.title
    if type(identifier) == 'string' and identifier ~= '' and type(title) == 'string' and title ~= '' then
        TriggerServerEvent('dy_name_tag:adminSetTitle', identifier, title)
    end
    if cb then cb({ ok = true }) end
end)

-- 管理端：调整指定 identifier 的超级标签颜色
RegisterNUICallback('admin_set_color', function(data, cb)
    local identifier = data and data.identifier
    local color = data and data.color
    if type(identifier) == 'string' and identifier ~= '' and type(color) == 'string' and color ~= '' then
        TriggerServerEvent('dy_name_tag:adminSetColor', identifier, color)
    end
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('toggle_self', function(data, cb)
    if data and type(data.value) == 'boolean' then
        myNameShow = data.value
    end
    if cb then cb({ ok = true }) end
end)

-- 玩家端：在 NUI 中选择并应用新的超级标签
RegisterNUICallback('set_super_title', function(data, cb)
    local title = data and data.title
    if type(title) == 'string' and title ~= '' then
        TriggerServerEvent('dy_name_tag:setSuperTitle', title)
    end
    if cb then cb({ ok = true }) end
end)

-- 关闭统一 NUI 的回调
RegisterNUICallback('close_menu', function(_, cb)
    closeNameTagUI()
    if cb then cb({ ok = true }) end
end)

-- /nametagui：玩家端打开/关闭统一 NUI
RegisterCommand('nametagui', function()
    if isNuiOpen then
        closeNameTagUI()
    else
        openNameTagUI()
    end
end, false)

-- 服务端推送管理端某个 identifier 的最新超级标签档案到 NUI
RegisterNetEvent('dy_name_tag:adminEntryData', function(identifier, entry)
    SendNUIMessage({
        type = 'update_state',
        mode = 'admin',
        payload = {
            admin = {
                identifier = identifier,
                entry = entry,
            }
        }
    })
end)

-- 初始化入口：等待框架 bridge 标记 M.loggedIn，再初始化本地配置与渲染逻辑
CreateThread(function()
    while true do
        if M and M.loggedIn then
            break
        end
        Wait(500)
    end

    -- 初始化配置缓存
    initLocalConfig()

    -- 设置隐藏区域
    setupHideZones()

    -- 启动主循环
    if namesVisible then
        CreateThread(playerStreamer)
    end
end)
