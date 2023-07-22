fx_version "adamant"
games { "rdr3" }
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

description 'The Core service for the Feather Framework'
author 'Feather @Bytesizd'
version '0.0.1'

shared_scripts {
    "/shared/data/*.lua",
    "/shared/helpers/*.lua",
    "/shared/services/*.lua",
    "/shared/main.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "/server/config.lua",
    "/server/helpers/*.lua",
    "/server/controllers/*.lua",
    "/server/services/*.lua",
    "/server/main.lua"
}

client_scripts {
    "/client/config.lua",
    "/client/helpers/*.lua",
    "/client/services/*.lua",
    "/client/main.lua"
}

dependencies {
    'oxmysql',
    'weathersync'
}
