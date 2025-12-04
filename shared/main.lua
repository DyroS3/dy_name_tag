-- shared/main.lua - 头顶名字系统的共享工具函数与绘制封装

-- 模块级配置缓存（避免每帧读取 Config）
local CFG_SCALE = 1.2
local CFG_FONT = 42
local CFG_BASE_TEXT_SCALE = 0.35
local CFG_STREAM_DISTANCE = 20

--- 初始化显示配置缓存（在资源启动时调用一次）
function InitDisplayConfig()
    local ds = Config.DisPlaySetting and Config.DisPlaySetting.default
    if ds then
        CFG_SCALE = ds.scale or 1.2
        CFG_FONT = ds.fontId or 42
    end
    CFG_STREAM_DISTANCE = Config.StreamDistance or 20
end

--- Get localized string
---@param key string
---@param ... any
---@return string
function L(key, ...)
    if key then
        local str = Locales[Config.Locale][key]
        if str then
            return string.format(str, ...)
        else
            return "ERR_TRANSLATE_" .. (key) .. "_404"
        end
    else
        return "ERR_TRANSLATE_404"
    end
end
--- 优化版 3D 文本绘制（零内存分配，使用数字索引）
---@param x number
---@param y number
---@param z number
---@param lines table 预分配的文本行数组，每行包含 text, r, g, b, x, y
---@param lineCount number 实际要绘制的行数
---@param scale number 统一缩放
---@param alpha number 统一透明度 0-255
function DrawText3DOptimized(x, y, z, lines, lineCount, scale, alpha)
    SetDrawOrigin(x, y, z, 0)

    for i = 1, lineCount do
        local line = lines[i]
        SetTextScale(scale, scale)
        SetTextFont(CFG_FONT)
        SetTextCentre(true)
        SetTextColour(line.r, line.g, line.b, alpha)
        SetTextOutline()
        BeginTextCommandDisplayText("STRING")
        AddTextComponentString(line.text)
        EndTextCommandDisplayText(line.x, line.y)
    end

    ClearDrawOrigin()
end
