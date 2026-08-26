fx_version "cerulean"
game "rdr3"
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

description 'The Core service for the Feather Framework'
author 'Feather @Bytesizd'
name 'feather-core'
version '0.1.8'

github_version_check 'true'
github_version_type 'release'
github_ui_check 'true'
github_link 'https://github.com/FeatherFramework/feather-core'


shared_scripts {
    "/config.lua",
    "/shared/data/*.lua",
    "/shared/helpers/*.lua",
    "/shared/services/*.lua",
    "/locale/*.lua",
    "/shared/main.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "/server/helpers/*.lua",
    "/server/controllers/*.lua",
    "/server/services/*.lua",
    "/server/main.lua"
}

client_scripts {
    "/client/imports.lua",
    "/client/helpers/*.lua",
    "/client/services/*.lua",
    "/client/main.lua"
}

-- Minimal clipboard-relay page only -- the player HUD moved to feather-hud.
-- See ui/index.html.
ui_page {
    "ui/index.html"
}

files {
    "ui/index.html"
}


dependencies {
    'oxmysql',
    'weathersync',
    'feather-menu'
}
