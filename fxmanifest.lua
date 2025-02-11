fx_version 'cerulean'
game 'gta5'

author 'R1mus'
description 'Sistema de trabajo de basurero para QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js'
}

lua54 'yes'