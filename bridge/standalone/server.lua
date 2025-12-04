-- bridge/standalone/server.lua
-- 纯 GTA standalone 模式下的服务端桥接: 使用原生 GetPlayerName

if (Config.Framework or 'standalone'):lower() ~= 'standalone' then
    return
end

M = M or {}

--- 获取玩家显示名字 (standalone)
--- @param source number 玩家 serverId
--- @return string displayName 显示在头顶的名字
--- @diagnostic disable-next-line: duplicate-set-field
function M.GetPlayerDisplayName(source)
    local name = GetPlayerName(source)
    if name and name ~= "" then
        return name
    end
    return ("%s"):format(source)
end
