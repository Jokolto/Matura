extends Node
# Uses dictionaries and consts instead of classes since classes work funny in gdscript

# Python or not python, that is the question
const USE_PYTHON_SERVER = false   # must be true for experimenting 
const DEBBUGGING = true # disables some stuff if true (tutorial, cutscene)

# for experimentation
const EXPERIMENTING = true      # alternative name could be COLLECTING_DATA. If true collects data and sends to python to save in csv
var bot_player = true            # makes player not controlable, and replace with generic behavior defined in player.gd
var infinite_ammo_ranged = true
var no_weapon_variation = true  # makes all enemies spawn just with some default weapon defined in next line
var path_to_default_weapon_resource = "res://scenes/objects/resources/guns/handgun.tres"

var items_enabled = false        # skips upgrade panel
var enemy_stat_scaling = false   # specific stat increase set in Entitiesmanager, this disables it.
var enemy_amount_per_wave_increase = false   # normally each wave 10 percent more enemies is spawned with base amount 4. To change base go to Entitiesmanager 



enum EnemyTypes {Melee, Ranged, Generic}
enum WeaponType {MELEE, RANGED}
var EnemyWeaponType
var PlayerNickName: String

var ClientConfig = {
	"HOST": "127.0.0.1",
	"PORT": 9000,
}

# looks braindead, but it is the way. (in case reward events names on server is different for some reason)
var RewardEvents = {
	"TOOK_DAMAGE": "TOOK_DAMAGE",
	"HIT_PLAYER": "HIT_PLAYER",
	"TIME_ALIVE": "TIME_ALIVE",
	"DODGED_BULLET": "DODGED_BULLET",
	"RETREATED": "RETREATED",
	"WASTED_MOVEMENT": "WASTED_MOVEMENT",
	"MOVED_CLOSER": "MOVED_CLOSER",
	"MISSED": "MISSED",
	"DIED": "DIED",
	"STUCK": "STUCK"
}

# used for leaderboards now, should not be shared
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
	"HIT_PLAYER": 14.0,
	"RETREATED": -0.2,
	"WASTED_MOVEMENT": -0.1,
	"MOVED_CLOSER": 0.05,
	"MISSED": -0.2,
	"DIED": -7,
	"STUCK": -5
}

# test config for experiments, should be set through python when conducting experiments
var run_id = 0
var config = "q_only" # should be only those: random, q_only, selection_only, selection_mut   // could also make an enum but idk how they interact with python
var seed_n = 0  # can't name seed, cause it is a method to set it. This seed is set in Gamemanager at begin if experimenting
