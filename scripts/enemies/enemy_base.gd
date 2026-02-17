extends CharacterBody3D
class_name EnemyBase

# ============================================
# BASE ENEMY - All enemies inherit from this
# ============================================

# Enemy Types
enum EnemyType { GRUNT, SHOOTER, RUSHER }

# Stats (override in child classes)
@export var enemy_type: EnemyType = EnemyType.GRUNT
@export var max_health: float = 100.0
@export var speed: float = 4.0
@export var damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var detection_range: float = 15.0

# Drop settings
@export var coin_drop_min: int = 5
@export var coin_drop_max: int = 15
@export var health_drop_chance: float = 0.3  # 30% chance

# State
var current_health: float
var player: Node3D = null
var can_attack: bool = true
var is_dead: bool = false

# References
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health_label: Label3D = $HealthLabel
@onready var anim_player: AnimationPlayer = $Body/AnimationPlayer
@onready var body: Node3D = $Body

# Health bar
var health_bar_container: Node3D
var health_bar_fill: MeshInstance3D

# Preload drop scenes
var coin_scene: PackedScene
var health_pickup_scene: PackedScene

signal enemy_died

func _ready():
	add_to_group("enemies")
	current_health = max_health
	
	# Load drop scenes
	coin_scene = load("res://scenes/pickups/coin.tscn")
	health_pickup_scene = load("res://scenes/pickups/health_pickup.tscn")
	
	# Create health bar
	create_health_bar()
	
	# Wait then find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	# Setup navigation
	if nav_agent:
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = 1.0
	
	# Call child setup
	_setup_enemy_type()
	
	update_health_display()
	print(EnemyType.keys()[enemy_type], " spawned with ", current_health, " HP!")

# Override in child classes
func _setup_enemy_type():
	pass

func create_health_bar():
	health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar3D"
	health_bar_container.position.y = 2.0
	add_child(health_bar_container)
	
	# Background
	var bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(1.2, 0.15, 0.05)
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.2, 0.2, 0.2)
	bg.set_surface_override_material(0, bg_mat)
	health_bar_container.add_child(bg)
	
	# Fill
	health_bar_fill = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(1.1, 0.12, 0.06)
	health_bar_fill.mesh = fill_mesh
	health_bar_fill.position.z = 0.02
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color.GREEN
	health_bar_fill.set_surface_override_material(0, fill_mat)
	health_bar_container.add_child(health_bar_fill)

func _physics_process(delta):
	if is_dead:
		return
	
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Only act if player is within detection range
	if distance <= detection_range:
		if nav_agent:
			nav_agent.target_position = player.global_position
		
		if distance > attack_range:
			move_toward_player(delta)
			play_animation("walk")
		else:
			if can_attack:
				attack_player()
		
		look_at_player()
	else:
		play_animation("idle")
	
	face_health_bar_to_camera()

func move_toward_player(delta):
	if nav_agent == null or nav_agent.is_navigation_finished():
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
	else:
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
	
	if not is_on_floor():
		velocity.y -= 20 * delta
	
	move_and_slide()

func look_at_player():
	if player == null:
		return
	var look_pos = player.global_position
	look_pos.y = global_position.y
	if body:
		body.look_at(look_pos)
		body.rotation.y += PI  # Adjust if model faces wrong way

func attack_player():
	can_attack = false
	play_animation("attack")
	
	# Deal damage
	if player.has_method("take_damage"):
		player.take_damage(damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: float):
	if is_dead:
		return
	
	current_health -= amount
	update_health_display()
	flash_damage()
	play_animation("hit")
	
	if current_health <= 0:
		die()

func update_health_display():
	var health_percent = current_health / max_health
	
	if health_label:
		health_label.text = "%d/%d" % [int(current_health), int(max_health)]
		if health_percent > 0.6:
			health_label.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_label.modulate = Color.YELLOW
		else:
			health_label.modulate = Color.RED
	
	if health_bar_fill:
		health_bar_fill.scale.x = max(health_percent, 0.01)
		health_bar_fill.position.x = -(1.1 * (1 - health_percent)) / 2
		var mat = health_bar_fill.get_surface_override_material(0)
		if mat:
			if health_percent > 0.6:
				mat.albedo_color = Color.GREEN
			elif health_percent > 0.3:
				mat.albedo_color = Color.YELLOW
			else:
				mat.albedo_color = Color.RED

func face_health_bar_to_camera():
	var camera = get_viewport().get_camera_3d()
	if camera and health_bar_container:
		var look_pos = camera.global_position
		look_pos.y = health_bar_container.global_position.y
		health_bar_container.look_at(look_pos)
		health_bar_container.rotate_y(PI)

func flash_damage():
	var mesh = get_node_or_null("Body/MeshInstance3D")
	if mesh == null:
		mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			var original = mat.albedo_color
			mat.albedo_color = Color.RED
			await get_tree().create_timer(0.1).timeout
			if not is_dead:
				mat.albedo_color = original

func play_animation(anim_name: String):
	if anim_player == null:
		return
	if anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func die():
	if is_dead:
		return
	
	is_dead = true
	play_animation("death")
	
	# Notify game manager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.enemy_died()
	
	# Drop loot
	drop_loot()
	
	enemy_died.emit()
	
	# Wait for death animation then remove
	if anim_player and anim_player.has_animation("death"):
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	queue_free()

func drop_loot():
	var drop_position = global_position + Vector3(0, 0.5, 0)
	
	# Drop coins
	if coin_scene:
		var coin_amount = randi_range(coin_drop_min, coin_drop_max)
		for i in range(mini(coin_amount / 5, 5)):  # Max 5 coin objects
			var coin = coin_scene.instantiate()
			get_tree().root.add_child(coin)
			coin.global_position = drop_position
			coin.value = randi_range(1, 5)
			# Add random scatter
			coin.global_position.x += randf_range(-0.5, 0.5)
			coin.global_position.z += randf_range(-0.5, 0.5)
	
	# Chance to drop health
	if health_pickup_scene and randf() < health_drop_chance:
		var health = health_pickup_scene.instantiate()
		get_tree().root.add_child(health)
		health.global_position = drop_position
