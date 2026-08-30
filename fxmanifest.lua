fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

description 'The Core service for the Feather Framework'
author 'Feather Framework'
name 'feather-core'
version '0.3.1'

shared_scripts {
    '/config.lua',
    '/shared/helpers/*.lua',
    '/shared/services/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '/server/migrations/*.lua',
    '/server/helpers/*.lua',
    '/server/services/*.lua',
    '/server/main.lua'
}

dependencies {
    'oxmysql'
}
