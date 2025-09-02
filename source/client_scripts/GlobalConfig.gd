extends Node
# Uses dictionaries and consts instead of classes since classes work funny in gdscript

# Python or not python, that is the question
const USE_PYTHON_SERVER = false
const DEBBUGGING = true

enum EnemyTypes {Melee, Ranged, Generic}
enum WeaponType {MELEE, RANGED}
var EnemyWeaponType
var PlayerNickName: String

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
	"MISSED": "MISSED",
	"DIED": "DIED"
}

# makes it kind of dangerous to make it public on github. This service does not work in html build, cause it uses http not s
var DreamloConfig = {
	"public": "http://dreamlo.com/lb/68b2c88d8f40bb12e078c937",
	"private": "http://dreamlo.com/lb/Lg6YUy6iREiToPXTcR4jSQTNhHEOU4NU-AFyOnc-K-Kg"
}
# used for leaderboards now, also should not be shared
const FIREBASE_URL = "https://maturgamelb-default-rtdb.europe-west1.firebasedatabase.app/scores.json"

var GameConfig = {
	"X_MAP_SIZE" : 3000,  # very approximately 
	"Y_MAP_SIZE" : 2000,  # also /
}

# If not using python server
# Q-learning constants 
const LEARNING_RATE = 0.2
const DISCOUNT_FACTOR = 0.9
const EPSILON = 0.2

var REWARDS := {
	"TOOK_DAMAGE": -2.0,
	"TIME_ALIVE": 0.05,
	"HIT_PLAYER": 8.0,
	"RETREATED": -0.2,
	"WASTED_MOVEMENT": -0.1,
	"MOVED_CLOSER": 0.05,
	"MISSED": -0.2,
	"DIED": -10
}
