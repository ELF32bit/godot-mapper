const MAPPER_GAMES: Dictionary = {
	"Generic": {
		"game_directory": "res://mapping/generic",
		"alternative_game_directories": ["res://mapping/quake"],
		"game_loader": MapperSettings.DEFAULT_GAME_LOADER,
	},
	"Quake": {
		"game_directory": "res://mapping/quake",
		"game_loader": MapperSettings.QUAKE_GAME_LOADER,
		"skip_material_affects_collision": false,
		"prefer_static_lighting": true,
	}
}
