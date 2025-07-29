extends Node
# Uses dictionaries instead of classes since classes work funny in gdscript

var ClientConfig = {
	"HOST": "127.0.0.1",
	"PORT": 9000,
}

# looks braindead, but it is the way
var RewardEvents = {
	"TOOK_DAMAGE": "TOOK_DAMAGE",
	"HIT_PLAYER": "HIT_PLAYER",
	"TIME_ALIVE": "TIME_ALIVE",
	"DODGED_BULLET": "DODGED_BULLET",
	"RETREATED": "RETREATED",
	"WASTED_MOVEMENT": "WASTED_MOVEMENT",
	"MOVED_CLOSER": "MOVED_CLOSER",
	"MISSED": "MISSED"
}


var GameConfig = {
	"X_MAP_SIZE" : 3000,  # very approximately 
	"Y_MAP_SIZE" : 2000,  # also /
}

# not doing anything yet
var DisplayConfig = {
	"RESOLUTION": Vector2i(1200, 800),
	"SHOW_DEBUG_UI": false
}
