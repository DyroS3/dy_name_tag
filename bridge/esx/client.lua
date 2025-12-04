-- bridge/esx/client.lua
-- ESX 框架下的客户端桥接
-- 当前资源主要在服务端获取 RP 名字, 客户端暂不直接依赖 ESX

if (Config.Framework or 'standalone'):lower() ~= 'esx' then
    return
end

M = M or {}

local ESX = ESX

-- 优先通过 exports 获取 ESX 对象（es_extended 新版）
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

-- 标记本地玩家已完成 ESX 登录/角色加载
RegisterNetEvent('esx:playerLoaded', function()
    M.loggedIn = true
end)

--- 预留: 客户端获取玩家显示名字
--- 这里保持与 standalone 行为一致, 方便后续根据需要扩展
--- @param player number 本地玩家索引
--- @return string displayName
--- @diagnostic disable-next-line: duplicate-set-field
function M.GetPlayerDisplayName(player)
    return GetPlayerName(player) or ("Player %s"):format(player)
end

--- 获取本地玩家当前职业名称（job.name），例如 "police"
--- @return string|nil
function M.GetPlayerJobName()
    if not ESX or not ESX.GetPlayerData then return nil end

    local data = ESX.GetPlayerData()
    if not data or not data.job then return nil end

    return data.job.name
end

--- 判断本地玩家是否为指定职业
--- @param jobName string
--- @return boolean
function M.IsJob(jobName)
    if not jobName then return false end
    local current = M.GetPlayerJobName()
    return current ~= nil and current == jobName
end
