fx_version "adamant"
games { "rdr3" }
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

description 'The Core service for the Feather Framework'
author 'BCC Scripts'
name 'feather-core'
version '1.0.0'

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
    "/client/helpers/*.lua",
    "/client/services/notifications.lua",
    "/client/services/*.lua",
    "/client/main.lua"
}

ui_page {
    "ui/index.html"
}

files {
    "ui/index.html",
    "ui/js/*.*",
    "ui/css/*.*",
    "ui/fonts/*.*",
    "ui/img/*.*"
}


dependencies {
    'oxmysql',
    'weathersync'
}