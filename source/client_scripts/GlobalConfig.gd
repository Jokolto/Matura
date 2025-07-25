extends Node
# Uses dictionaries instead of classes since classes work funny in gdscript

var ClientConfig = {
	"HOST": "127.0.0.1",
	"PORT": 9000,
}

var RewardEvents = {
	"TOOK_DAMAGE": "TOOK_DAMAGE",
	"HIT_PLAYER": "HIT_PLAYER",
	"TIME_ALIVE": "TIME_ALIVE",
	"DODGED_BULLET": "DODGED_BULLET",
	"RETREATED": "RETREATED",
	"WASTED_MOVEMENT": "WASTED_MOVEMENT",
	"MOVED_CLOSER": "MOVED_CLOSER"
}

# not doing anything yet
var GameConfig = {
	"MAP_SIZE" = null
}

# not doing anything yet
var DisplayConfig = {
	"RESOLUTION": Vector2i(1200, 800),
	"SHOW_DEBUG_UI": false
}
