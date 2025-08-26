extends Node
# Uses dictionaries and consts instead of classes since classes work funny in gdscript

# Python or not python, that is the question
const USE_PYTHON_SERVER = false

enum EnemyTypes {Melee, Ranged, Generic}
enum WeaponType {MELEE, RANGED}
var EnemyWeaponType

var ClientConfig = {
	"HOST": "127.0.0.1",
	"PORT": 9000,
}

# looks braindead, but it is the way. (no it is not)
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

# If not using python server
# Q-learning constants 
const LEARNING_RATE = 0.1
const DISCOUNT_FACTOR = 0.9
const EPSILON = 0.1

var REWARDS := {
	"TOOK_DAMAGE": -1.0,
	"TIME_ALIVE": 0.05,
	"HIT_PLAYER": 15.0,
	"RETREATED": -2.0,
	"WASTED_MOVEMENT": -1.0,
	"MOVED_CLOSER": 1.0,
	"MISSED": 0.0,
}
