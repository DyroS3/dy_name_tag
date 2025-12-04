-- bridge/qb/client.lua
-- QBCore 框架下的客户端桥接
-- 当前资源主要在服务端获取 RP 名字, 客户端暂不直接依赖 QBCore

if (Config.Framework or 'standalone'):lower() ~= 'qb' then
    return
end

M = M or {}

-- 标记本地玩家已完成 QB 登录/角色加载
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    M.loggedIn = true
end)

RegisterNetEvent('QBCore:Client:PlayerLoaded', function()
    M.loggedIn = true
end)

--- 预留: 客户端获取玩家显示名字
--- 这里保持与 standalone 行为一致, 后续如需从服务端同步 RP 名字可在此扩展
--- @param player number 本地玩家索引
--- @return string displayName
--- @diagnostic disable-next-line: duplicate-set-field
function M.GetPlayerDisplayName(player)
    return GetPlayerName(player) or ("Player %s"):format(player)
end
