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
	"WASTED_MOVEMENT": "WASTED_MOVEMENT"
}

var DisplayConfig = {
	"RESOLUTION": Vector2i(1280, 720),
	"SHOW_DEBUG_UI": true
}
