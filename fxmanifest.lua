fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'cdion.es'
name 'codeon-enginetoggle'
description 'Owner-only vehicle engine toggle'

shared_script 'config.lua'

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'oxmysql'
}

--[[
    thank you very much for downloading the script, it was made with lots of love by cdion.es
]]