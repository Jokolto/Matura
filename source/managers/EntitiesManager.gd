extends Node


# These are also set in level.gd at the begining. Needing to reset those in level.gd is one downside of this being global singleton.
var enemies_per_wave: int = 0
var enemies_spawned: int = 0
var current_wave: int = 0
var wave_active: bool = false
var spawn_active: bool = false
var enemies_alive: int = 0


var friendly_fire = false

var base_amount: int = 4 # first wave
var growth_rate: float = 1.1
var enemy_count_func = func(wave: int) -> int:
	return floor(base_amount * pow(growth_rate, wave))

# If I want to end wave based on time instead of kill count. Also to record time for some data collection
var wave_duration: float = -1
var wave_timer: float = 0.0  # sec
var wave_timer_discrete: int = 0  # sec, is needed for condition, when to record snapshots

var player_heal_after_wave_percentage: float = 0.25
# items can affect this. used for vertical scaling of diffuculty
var enemy_speed_mul: float = 1 
var enemy_hp_mul: float = 1
var enemy_dmg_mul: float = 1


var enemy_fitness: Dictionary = {}

# to display at the end
var total_enemies_killed = 0
var won_time_sec: float = 0.0

signal wave_end(fitness_dict)
signal wave_start

func _ready() -> void:
	if not GlobalConfig.enemy_amount_per_wave_increase:
		enemy_count_func = func(_wave: int) -> int:
			return base_amount

func _process(delta):
	if not wave_active:
		return
	wave_timer += delta
	if floor(wave_timer) > wave_timer_discrete:
		wave_timer_discrete = floor(wave_timer) 
		
	if (enemies_spawned >= enemies_per_wave) or (wave_timer >= wave_duration and wave_duration > 0):
		if enemies_alive <= 0:
			end_wave()
			return
		disable_spawning()


func disable_spawning():
	if spawn_active:
		spawn_active = false
		Logger.log("Spawning ended (enemy count)", "INFO")


func start_wave():
	current_wave += 1
	enemies_per_wave = enemy_count_func.call(current_wave)
	enemies_spawned = 0
	wave_timer = 0.0
	wave_timer_discrete = 0
	wave_active = true
	spawn_active = true

	if current_wave % 4 == 0 and GlobalConfig.enemy_stat_scaling: # every 4th wave, enemies get 10 percent stronger if it is turned on
		enemy_dmg_mul *= 1.1
		enemy_speed_mul *= 1.1
		enemy_hp_mul *= 1.1
	
	Logger.log("Wave %d started" % current_wave, "INFO")
	wave_start.emit()
	
func end_wave():
	wave_active = false
	Logger.log("Wave ended (enemies are dead)", "INFO")
	wave_end.emit(enemy_fitness)
	enemy_fitness = {}


func _on_player_death():
	wave_active = false
	spawn_active = false

func _on_enemy_death(enemy: Enemy):
	total_enemies_killed += 1
	enemies_alive -= 1
	enemy_fitness[enemy.enemy_id] = enemy.fitness
	
