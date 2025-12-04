-- bridge/standalone/client.lua
-- 纯 GTA standalone 模式下的客户端桥接
-- 当前资源暂未在客户端侧使用框架相关接口，此文件预留以保证结构一致

if (Config.Framework or 'standalone'):lower() ~= 'standalone' then
    return
end

M = M or {}

-- 在纯 standalone 模式下, 使用 NetworkIsPlayerActive 检测玩家进入会话后标记为已登录
CreateThread(function()
    while true do
        if NetworkIsPlayerActive(PlayerId()) then
            M.loggedIn = true
            break
        end
        Wait(500)
    end
end)

--- 预留: 客户端获取玩家显示名字
--- 实际显示名字仍由服务器逻辑决定，此处仅做占位
--- @param player number 本地玩家索引 (GetPlayerFromServerId 等)
--- @return string displayName
--- @diagnostic disable-next-line: duplicate-set-field
function M.GetPlayerDisplayName(player)
    -- 直接返回游戏内名称作为占位实现
    return GetPlayerName(player) or ("%s"):format(player)
end
