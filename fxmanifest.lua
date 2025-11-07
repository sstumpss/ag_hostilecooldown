fx_version 'cerulean'
game 'gta5'

author 'stumps'
description 'AG Hostile Cooldown System'
version '1.0.0'
lua54 'yes'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

client_script 'client.lua'
server_scripts {
    'version_checker.lua',
    'server.lua'
}
