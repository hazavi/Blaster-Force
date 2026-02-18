extends Node

# References
@export var player_spawn: Marker3D
@export var exit_door: Node3D
@export var enemy_spawns: Array[Node] = []

# ✅ NEW: Add level number export
@export var level_number: int = 1

# Spawn mode
enum SpawnMode { RANDOM, SEQUENTIAL, GRUNT_ONLY, SHOOTER_ONLY, RUSHER_ONLY }
@export var spawn_mode: SpawnMode = SpawnMode.RANDOM

# Enemy scenes
var grunt_scene: PackedScene = null
var shooter_scene: PackedScene = null
var rusher_scene: PackedScene = null
var basic_enemy_scene: PackedScene = null

# Game Manager reference
var game_manager: Node

# Track spawned enemies
var spawned_enemies: Array[Node] = []

# Exit trigger
var exit_trigger: Area3D = null


func _ready():
	# Clear any leftover pickups from previous games
	clear_all_pickups()
	
	load_enemy_scenes()
	
	game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.all_enemies_dead.connect(_on_all_enemies_dead)
	
	spawn_player()
	
	# ✅ FIX: Use the exported level_number instead of hardcoded 1
	if game_manager:
		game_manager.start_level(level_number)
		print("🎮 Started Level ", level_number)
	
	spawn_enemies()


func clear_all_pickups():
	"""Remove all coins and health pickups from previous run"""
	# Clear coins
	var coins = get_tree().get_nodes_in_group("coins")
	for coin in coins:
		coin.queue_free()
	
	# Clear health pickups
	var health_pickups = get_tree().get_nodes_in_group("health_pickups")
	for pickup in health_pickups:
		pickup.queue_free()
	
	print("Cleared ", coins.size(), " coins and ", health_pickups.size(), " health pickups")


func load_enemy_scenes():
	if ResourceLoader.exists("res://scenes/enemies/grunt.tscn"):
		grunt_scene = load("res://scenes/enemies/grunt.tscn")
	
	if ResourceLoader.exists("res://scenes/enemies/shooter.tscn"):
		shooter_scene = load("res://scenes/enemies/shooter.tscn")
	
	if ResourceLoader.exists("res://scenes/enemies/rusher.tscn"):
		rusher_scene = load("res://scenes/enemies/rusher.tscn")
	
	if ResourceLoader.exists("res://scenes/enemies/enemy.tscn"):
		basic_enemy_scene = load("res://scenes/enemies/enemy.tscn")


func spawn_player():
	var player = get_tree().get_first_node_in_group("player")
	
	if player and player_spawn:
		player.global_position = player_spawn.global_position


func spawn_enemies():
	spawned_enemies.clear()
	
	for i in range(enemy_spawns.size()):
		var spawn_point = enemy_spawns[i]
		if spawn_point == null:
			continue
		
		var enemy = get_enemy_for_spawn(i)
		if enemy == null:
			continue
		
		add_child(enemy)
		enemy.global_position = spawn_point.global_position
		spawned_enemies.append(enemy)
		
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
		
		if game_manager:
			game_manager.add_enemy()


func _on_enemy_died(enemy: Node):
	if enemy in spawned_enemies:
		spawned_enemies.erase(enemy)
	
	if spawned_enemies.size() == 0:
		call_deferred("_check_all_dead")


func _check_all_dead():
	await get_tree().process_frame
	
	var enemies_in_scene = get_tree().get_nodes_in_group("enemies")
	
	if enemies_in_scene.size() == 0:
		_on_all_enemies_dead()


func get_enemy_for_spawn(index: int) -> Node:
	var scene_to_use: PackedScene = null
	
	match spawn_mode:
		SpawnMode.RANDOM:
			scene_to_use = get_random_enemy()
		SpawnMode.SEQUENTIAL:
			scene_to_use = get_sequential_enemy(index)
		SpawnMode.GRUNT_ONLY:
			scene_to_use = grunt_scene
		SpawnMode.SHOOTER_ONLY:
			scene_to_use = shooter_scene
		SpawnMode.RUSHER_ONLY:
			scene_to_use = rusher_scene
	
	if scene_to_use == null:
		scene_to_use = basic_enemy_scene
	
	if scene_to_use == null:
		return null
	
	return scene_to_use.instantiate()


func get_random_enemy() -> PackedScene:
	var available: Array[PackedScene] = []
	
	if grunt_scene:
		available.append(grunt_scene)
	if shooter_scene:
		available.append(shooter_scene)
	if rusher_scene:
		available.append(rusher_scene)
	
	if available.is_empty():
		return basic_enemy_scene
	
	return available[randi() % available.size()]


func get_sequential_enemy(index: int) -> PackedScene:
	var scenes: Array[PackedScene] = []
	
	if grunt_scene:
		scenes.append(grunt_scene)
	if shooter_scene:
		scenes.append(shooter_scene)
	if rusher_scene:
		scenes.append(rusher_scene)
	
	if scenes.is_empty():
		return basic_enemy_scene
	
	return scenes[index % scenes.size()]


func _on_all_enemies_dead():
	print("=== ALL ENEMIES DEAD - OPENING EXIT! ===")
	open_exit_door()
	
	if game_manager:
		game_manager.complete_level()


func open_exit_door():
	if exit_door == null:
		return
	
	# Destroy the door
	exit_door.queue_free()


func spawn_enemy_at(position: Vector3, type: String = "random") -> Node:
	var scene_to_use: PackedScene = null
	
	match type.to_lower():
		"grunt":
			scene_to_use = grunt_scene
		"shooter":
			scene_to_use = shooter_scene
		"rusher":
			scene_to_use = rusher_scene
		"random":
			scene_to_use = get_random_enemy()
		_:
			scene_to_use = basic_enemy_scene
	
	if scene_to_use == null:
		scene_to_use = basic_enemy_scene
	
	if scene_to_use == null:
		return null
	
	var enemy = scene_to_use.instantiate()
	add_child(enemy)
	enemy.global_position = position
	spawned_enemies.append(enemy)
	
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	
	if game_manager:
		game_manager.add_enemy()
	
	return enemy
