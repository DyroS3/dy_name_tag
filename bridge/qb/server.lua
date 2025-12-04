-- bridge/qb/server.lua
-- QBCore 框架下的服务端桥接: 使用 charinfo.firstname .. " " .. lastname 作为显示名字

if (Config.Framework or 'standalone'):lower() ~= 'qb' then
    return
end

M = M or {}

local QBCore = QBCore

-- 尝试通过 exports 获取 QBCore 对象
if not QBCore and exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- 构建 "职业-职称" 文本 (QB job)
---@param job table|nil
---@return string|nil
local function buildJobTitle(job)
    if not job then return nil end

    local jobLabel = job.label or job.name or ""
    local gradeLabel = job.grade and (job.grade.label or job.grade.name) or ""

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
---@param src number
---@param tPlayer table
---@param job table|nil
local function updateNameTagState(src, tPlayer, job)
    if not src or not tPlayer or not tPlayer.PlayerData or not tPlayer.PlayerData.charinfo then return end

    local info = tPlayer.PlayerData.charinfo
    local first = info.firstname or ""
    local last = info.lastname or ""
    local full = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
    if full == "" then return end

    local jobTitle = buildJobTitle(job)

    local identifier = (tPlayer.PlayerData and (tPlayer.PlayerData.citizenid or tPlayer.PlayerData.license or tPlayer.PlayerData.steam)) or nil

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

    local player = Player(src)
    if player and player.state and player.state.set then
        local cur = player.state.dy_nameTag or {}
        local superTag = cur.superTag
        local superColor = cur.superColor
        player.state:set('dy_nameTag', {
            displayName = full,
            jobTitle = jobTitle,
            jobName = job and job.name or nil,
            vipTag = vipTag,
            vipColor = vipColor,
            superTag = superTag,
            superColor = superColor,
        }, true)
    end
end

-- QB: 玩家加载完成时, 将名字与职业同步到 dy_nameTag
-- 新版常见事件: QBCore:Server:PlayerLoaded (传入 Player 对象)
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if type(player) == 'table' and player.PlayerData then
        local src = player.PlayerData.source or player.PlayerData.id or source
        updateNameTagState(src, player, player.PlayerData.job)
        if SyncSuperToState then
            SyncSuperToState(src)
        end
    end
end)

-- 兼容部分旧版/变体事件: QBCore:Server:OnPlayerLoaded (传入 source)
AddEventHandler('QBCore:Server:OnPlayerLoaded', function(src)
    if not QBCore or not QBCore.Functions or not QBCore.Functions.GetPlayer then return end
    local tPlayer = QBCore.Functions.GetPlayer(src)
    if tPlayer then
        updateNameTagState(src, tPlayer, tPlayer.PlayerData.job)
        if SyncSuperToState then
            SyncSuperToState(src)
        end
    end
end)

-- QB: 职业变更时, 同步更新职业-职称到 dy_nameTag
AddEventHandler('QBCore:Server:OnJobUpdate', function(src, job)
    if not src or not job or not QBCore or not QBCore.Functions or not QBCore.Functions.GetPlayer then return end

    local tPlayer = QBCore.Functions.GetPlayer(src)
    if not tPlayer then return end

    updateNameTagState(src, tPlayer, job)
end)

--- 根据 citizenId 获取玩家显示名字 (可选扩展接口)
--- @param citizenId string
--- @return string|nil displayName
function M.GetPlayerDisplayNameByCitizenId(citizenId)
    if not QBCore or not QBCore.Functions or not QBCore.Functions.GetPlayerByCitizenId then
        return nil
    end

    local tPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if tPlayer and tPlayer.PlayerData and tPlayer.PlayerData.charinfo then
        local info = tPlayer.PlayerData.charinfo
        local first = info.firstname or ""
        local last = info.lastname or ""
        local full = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
        if full ~= "" then
            return full
        end
    end

    return nil
end

--- 根据 source 获取玩家显示名字 (QB)
--- @param source number 玩家 serverId
--- @return string displayName
--- @diagnostic disable-next-line: duplicate-set-field
function M.GetPlayerDisplayName(source)
    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        local tPlayer = QBCore.Functions.GetPlayer(source)
        if tPlayer and tPlayer.PlayerData and tPlayer.PlayerData.charinfo then
            local info = tPlayer.PlayerData.charinfo
            local first = info.firstname or ""
            local last = info.lastname or ""
            local full = (first .. " " .. last):gsub("^%s+", ""):gsub("%s+$", "")
            if full ~= "" then
                return full
            end
        end
    end

    -- 如果有 citizenId, 也可以在你的代码中单独调用 M.GetPlayerDisplayNameByCitizenId

    -- 回退: 使用 GTA 原生名字
    local name = GetPlayerName(source)
    if name and name ~= "" then
        return name
    end

    return ("%s"):format(source)
end

--- 获取玩家唯一标识 (QB)
--- @param source number 玩家 serverId
--- @return string|nil identifier
---@diagnostic disable-next-line: duplicate-set-field
function M.GetIdentifier(source)
    if not QBCore or not QBCore.Functions or not QBCore.Functions.GetPlayer then
        return nil
    end

    local tPlayer = QBCore.Functions.GetPlayer(source)
    if not tPlayer or not tPlayer.PlayerData then return nil end

    local pd = tPlayer.PlayerData
    local identifier = pd.citizenid or pd.license or pd.steam
    if identifier and identifier ~= '' then
        return identifier
    end

    return nil
end

--- 判断是否为管理员 (QB)
--- 规则来源于 Config.AdminGroup: 支持 identifier= / group= / job= / jobwithgrade=
--- @param source number
--- @return boolean
---@diagnostic disable-next-line: duplicate-set-field
function M.IsAdmin(source)
    if not Config or not Config.AdminGroup or type(Config.AdminGroup) ~= 'table' then
        return false
    end

    if not QBCore or not QBCore.Functions or not QBCore.Functions.GetPlayer then
        return false
    end

    local tPlayer = QBCore.Functions.GetPlayer(source)
    if not tPlayer or not tPlayer.PlayerData then return false end

    local pd = tPlayer.PlayerData
    local identifier = pd.citizenid or pd.license or pd.steam

    local job = pd.job
    local jobName, jobGrade
    if job then
        jobName = job.name
        if job.grade then
            jobGrade = job.grade.level or job.grade
        end
    end

    local rules = Config.AdminGroup
    for i = 1, #rules do
        local rule = rules[i]
        if type(rule) == 'string' and rule ~= '' then
            if rule:sub(1, 11) == 'identifier=' and identifier then
                if identifier == rule:sub(12) then return true end
            elseif rule:sub(1, 6) == 'group=' then
                local groupName = rule:sub(7)
                if QBCore.Functions.HasPermission and QBCore.Functions.HasPermission(source, groupName) then
                    return true
                end
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