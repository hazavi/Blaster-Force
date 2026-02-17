extends Node

# ============================================
# GAME MANAGER
# ============================================

# Game state
var is_playing: bool = true
var current_level: int = 1

# Enemy tracking
var enemies_alive: int = 0
var total_enemies_spawned: int = 0
var enemies_killed: int = 0  # NEW: Track kills

# Level stats
var level_start_time: float = 0.0
var level_coins_collected: int = 0

# Signals
signal all_enemies_dead
signal level_started
signal level_completed
signal enemy_count_changed(count: int)
signal enemy_killed

func _ready():
	pass


func add_enemy() -> void:
	enemies_alive += 1
	total_enemies_spawned += 1
	enemy_count_changed.emit(enemies_alive)


func enemy_died() -> void:
	enemies_alive -= 1
	enemies_killed += 1  # NEW: Increment kill counter
	
	if enemies_alive < 0:
		enemies_alive = 0
	
	enemy_count_changed.emit(enemies_alive)
	enemy_killed.emit()
	
	check_all_enemies_dead()


func check_all_enemies_dead() -> void:
	if enemies_alive <= 0 and total_enemies_spawned > 0:
		enemies_alive = 0
		all_enemies_dead.emit()


func get_enemy_count() -> int:
	return enemies_alive


func get_enemies_killed() -> int:
	return enemies_killed


func reset_enemy_count() -> void:
	enemies_alive = 0
	total_enemies_spawned = 0
	enemies_killed = 0  # NEW: Reset kills


func start_level(level_number: int) -> void:
	current_level = level_number
	reset_enemy_count()
	level_coins_collected = 0
	level_start_time = Time.get_ticks_msec() / 1000.0
	is_playing = true
	level_started.emit()


func complete_level() -> void:
	is_playing = false
	level_completed.emit()


func go_to_next_level() -> void:
	current_level += 1
	var path = "res://scenes/levels/level_" + str(current_level) + ".tscn"
	
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func restart_level() -> void:
	reset_enemy_count()
	get_tree().reload_current_scene()


func go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func get_level_time() -> float:
	if level_start_time == 0.0:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - level_start_time


func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
