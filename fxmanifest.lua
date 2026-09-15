fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'
version '1.0.0'

shared_scripts {
	-- Uncomment when Config.EventProvider = 'vorp_lib'
	-- '@vorp_lib/import.lua',
	'config.lua',
	'locale.lua',
	'data/composites.lua',
}

client_scripts {
	'client/dataview.lua',
	'client/composites.lua',
}

server_scripts {
	'server/server.lua'
}

files {
	'locales/*.json',
}
