fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dy_name_tag'
author 'dINGYu'
description '一款功能丰富、高性能的 FiveM 玩家头顶名牌系统，支持多框架、自定义标签与 NUI 管理界面'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    'ox_lib/init.lua',
    'shared/main.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/**/server.lua',
    'server/main.lua',
}

client_scripts {
    'bridge/**/client.lua',
    'client/main.lua',
}

ui_page 'web/ui.html'

files {
    'web/ui.html',
    'web/ui.css',
    'web/i18n.js',
    'web/ui.js',
}