extends Node
# Uses dictionaries and consts instead of classes since classes work funny in gdscript

# Python or not python, that is the question
var USE_PYTHON_SERVER = true  # must be true for experimenting 
var DEBBUGGING = true # disables some stuff if true (tutorial, cutscene) enables ctr K to kill all enemies

# For experimentation
var EXPERIMENTING = true   # alternative name could be COLLECTING_DATA. If true collects data and sends to python to save in csv. also enables some of below parameter automatically
var bot_player = true       # makes player not controlable, and replace with generic behavior defined in player.gd
var no_q_learning = false    # makes enemies chose their actions randomly instead of using q learning. used for base config
var wave_time_threshold = 30    # seconds after which all enemies are killed in wave to ensure experiments are running forward. Used only when experimenting
var infinite_ammo_ranged = true
var no_weapon_variation = true  # makes all enemies spawn just with some default weapon defined in next line
var path_to_default_weapon_resource = "res://resources/weapons/guns/handgun.tres"
#var path_to_default_weapon_resource = "res://resources/weapons/melee/stick.tres"
var player_health = 999999    # overwrite player health, making player immortal (almost). Only used when experimenting
var player_starts_with_weapon = true # specific weapon is defined in level.gd

var menus_enabled = false      # skips main menu to go to main gameplay loop
var items_enabled = false       # skips upgrade panel
var enemy_stat_scaling = false   # specific stat increase set in Entitiesmanager, this disables it.
var enemy_amount_per_wave_increase = false   # normally each wave 10 percent more enemies is spawned with base amount 4. To change base go to Entitiesmanager 
var waves_amount = -1      # runs for this amount of waves and leaves. is actually set through python. this is defined in Gamemanager init
#

enum EnemyTypes {Melee, Ranged, Generic}
enum WeaponType {MELEE, RANGED}
var EnemyWeaponType
var PlayerNickName: String

var ClientConfig = {
	"HOST": "127.0.0.1",
	"PORT": 10000, 
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
	"STUCK": "STUCK",
}

# used for leaderboards now, prob should not be shared, but i care not. If someone decides to be nasty, let them be nasty, it is just one database. also it is already possible to read this ingame with inspect tools
const FIREBASE_URL = "https://maturgamelb-default-rtdb.europe-west1.firebasedatabase.app/scores.json"

# not really used
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
	"STUCK": -5,
	"DODGED_BULLET": 6
}

# test config for experiments, should be set through python when conducting experiments
var run_id = 0
var config = "" # should be only those: base, q_only, ga_only, gen_q_learning   // could also make an enum but idk how they interact with python
var seed_n = 0  # can't name seed, cause it is a method to set it. This seed is set in Gamemanager at begin if experimenting

# what each config does. Config effects work only if EXPERIMENTING in godot is true:
# base - enemies have random q values without rewards. Implemented in godot with no_q_learning parameter and in python with condition of config
# q_only - enemies learn intra wave, but not with each wave. Implemented in python server with not filling shared q table
# ga_only - enemies have random q values without rewards, but best are selected at wave end to be reproduced in next with some mutation. uses no_q_learning parameter in godot and in python with condition of config
# gen_q_learning - uses both algorithms, default in release.
