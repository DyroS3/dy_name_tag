-- bridge/esx/server.lua
-- ESX 框架下的服务端桥接: 使用 xPlayer.name 作为显示名字

if (Config.Framework or 'standalone'):lower() ~= 'esx' then
    return
end

M = M or {}

local ESX = ESX

-- 优先尝试通过 exports 获取 ESX 对象 (较新版本 es_extended)
if not ESX and exports and exports.es_extended and exports.es_extended.getSharedObject then
    ESX = exports.es_extended:getSharedObject()
end

-- 如果没有 exports 接口, 再尝试旧版事件方式获取 ESX
if not ESX then
    pcall(function()
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
    end)
end

-- 根据 ESX job 信息构建 "职业-职称" 文本
---@param job table
---@return string|nil
local function buildJobTitle(job)
    if not job then return nil end

    local jobLabel = job.label or job.name or ""
    local gradeLabel = job.grade_label or job.grade_name or (job.grade and job.grade.name) or ""

    local title
    if jobLabel ~= "" and gradeLabel ~= "" then
        title = jobLabel .. "-" .. gradeLabel
    elseif jobLabel ~= "" then
        title = jobLabel
    elseif gradeLabel ~= "" then
        title = gradeLabel
    else
        title = nil
    end

    return title
end

-- 统一更新名字与职业显示到 state bag: dy_nameTag = { displayName = ..., jobTitle = ... }
---@param playerId number
---@param xPlayer table
---@param job table|nil
local function updateNameTagState(playerId, xPlayer, job)
    if not playerId or not xPlayer then return end

    local name
    if xPlayer.getName then
        name = xPlayer.getName()
    else
        name = xPlayer.name
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local jobTitle = buildJobTitle(job)

    -- 计算是否为新玩家
    -- 模式1: 使用 ESX 的 getPlayTime (单位秒)
    -- 模式2: 使用数据库 users 表的 created_at 字段
    local isNew = false
    local threshold = (Config and Config.NewPlayerHours) or 72
    local mode = (Config and Config.NewPlayerMode) or 1

    if mode == 2 then
        -- 模式2: 数据库 created_at 时间判定
        local playerIdentifier
        if xPlayer.getIdentifier then
            playerIdentifier = xPlayer.getIdentifier()
        else
            playerIdentifier = xPlayer.identifier
        end

        if playerIdentifier then
            local hoursSinceCreated = MySQL.scalar.await(
                'SELECT TIMESTAMPDIFF(HOUR, created_at, NOW()) FROM users WHERE identifier = ?',
                { playerIdentifier }
            )
            if hoursSinceCreated and type(hoursSinceCreated) == 'number' and hoursSinceCreated < threshold then
                isNew = true
            end
        end
    else
        -- 模式1: ESX 游戏时长判定
        if xPlayer.getPlayTime then
            local ok, playtime = pcall(xPlayer.getPlayTime, xPlayer)
            if ok and type(playtime) == 'number' and playtime >= 0 then
                local hours = playtime / 3600
                if hours < threshold then
                    isNew = true
                end
            end
        end
    end

    local identifier
    if xPlayer.getIdentifier then
        identifier = xPlayer.getIdentifier()
    else
        identifier = xPlayer.identifier
    end

    local vipTag, vipColor
    if Config and Config.VipTags and identifier then
        for i = 1, #Config.VipTags do
            local v = Config.VipTags[i]
            if v.identifier == identifier then
                vipTag = v.tag
                vipColor = v.color
                break
            end
        end
    end

    local player = Player(playerId)
    if player and player.state and player.state.set then
        local cur = player.state.dy_nameTag or {}
        local superTag = cur.superTag
        local superColor = cur.superColor
        player.state:set('dy_nameTag', {
            displayName = name,
            jobTitle = jobTitle,
            jobName = job and job.name or nil,
            isNew = isNew,
            vipTag = vipTag,
            vipColor = vipColor,
            superTag = superTag,
            superColor = superColor,
        }, true)
    end
end

-- ESX: 玩家加载完成时, 将名字与职业同步到 dy_nameTag
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer, isNew)
    updateNameTagState(playerId, xPlayer, xPlayer and xPlayer.job or nil)
    if SyncSuperToState then
        SyncSuperToState(playerId)
    end
end)

-- ESX: 职业变更时, 同步更新职业-职称到 dy_nameTag
AddEventHandler('esx:setJob', function(playerId, job, lastJob)
    if not playerId or not job or not ESX or not ESX.GetPlayerFromId then return end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    updateNameTagState(playerId, xPlayer, job)
end)

--- 获取玩家显示名字 (ESX)
--- @param source number 玩家 serverId
--- @return string displayName 显示在头顶的名字
--- @diagnostic disable-next-line: duplicate-set-field
function M.GetPlayerDisplayName(source)
    if ESX and ESX.GetPlayerFromId then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and xPlayer.name and xPlayer.name ~= "" then
            return xPlayer.name
        end
    end

    -- 回退: 使用 GTA 原生名字，保证功能不中断
    local name = GetPlayerName(source)
    if name and name ~= "" then
        return name
    end

    return ("%s"):format(source)
end

--- 获取玩家唯一标识 (ESX)
--- @param source number 玩家 serverId
--- @return string|nil identifier
---@diagnostic disable-next-line: duplicate-set-field
function M.GetIdentifier(source)
    if not ESX or not ESX.GetPlayerFromId then return nil end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    if xPlayer.getIdentifier then
        local id = xPlayer.getIdentifier()
        if id and id ~= '' then return id end
    end

    if xPlayer.identifier and xPlayer.identifier ~= '' then
        return xPlayer.identifier
    end

    return nil
end

--- 判断是否为管理员 (ESX)
--- 规则来源于 Config.AdminGroup: 支持 identifier= / group= / job= / jobwithgrade=
--- @param source number
--- @return boolean
---@diagnostic disable-next-line: duplicate-set-field
function M.IsAdmin(source)
    if not Config or not Config.AdminGroup or type(Config.AdminGroup) ~= 'table' then
        return false
    end

    if not ESX or not ESX.GetPlayerFromId then
        return false
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local identifier
    if xPlayer.getIdentifier then
        identifier = xPlayer.getIdentifier()
    else
        identifier = xPlayer.identifier
    end

    local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
    local jobName, jobGrade
    if job then
        jobName = job.name
        if job.grade ~= nil then
            jobGrade = tonumber(job.grade) or job.grade
        end
    end

    local rules = Config.AdminGroup
    for i = 1, #rules do
        local rule = rules[i]
        if type(rule) == 'string' and rule ~= '' then
            if rule:sub(1, 11) == 'identifier=' and identifier then
                if identifier == rule:sub(12) then return true end
            elseif rule:sub(1, 6) == 'group=' and xPlayer.getGroup then
                local g = xPlayer.getGroup()
                if g == rule:sub(7) then return true end
            elseif rule:sub(1, 4) == 'job=' and jobName then
                if jobName == rule:sub(5) then return true end
            elseif rule:sub(1, 13) == 'jobwithgrade=' and jobName then
                local v = rule:sub(14)
                local sep = v:find('_', 1, true)
                if sep then
                    local rJob = v:sub(1, sep - 1)
                    local gradeStr = v:sub(sep + 1)
                    local gradeNum = tonumber(gradeStr)
                    if rJob == jobName and jobGrade and tonumber(jobGrade) == gradeNum then
                        return true
                    end
                end
            end
        end
    end

    return false
end
