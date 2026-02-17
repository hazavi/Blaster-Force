extends CharacterBody3D

# Stats
@export var max_health: float = 100.0
@export var speed: float = 4.0
@export var damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

# State
var current_health: float
var player: Node3D = null
var can_attack: bool = true
var is_dead: bool = false

# References
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health_label: Label3D = $HealthLabel

# Health bar references (created in script)
var health_bar_container: Node3D
var health_bar_fill: MeshInstance3D
var health_bar_bg: MeshInstance3D

signal enemy_died

func _ready():
	add_to_group("enemies")
	current_health = max_health
	
	# Create health bar
	create_health_bar()
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	if nav_agent:
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = 1.0
	
	update_health_display()
	print("Enemy spawned with ", current_health, " HP!")

func create_health_bar():
	# Container for health bar
	health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar3D"
	health_bar_container.position.y = 2.0  # Below the label
	add_child(health_bar_container)
	
	# Background (gray bar)
	health_bar_bg = MeshInstance3D.new()
	health_bar_bg.name = "Background"
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(1.2, 0.15, 0.05)
	health_bar_bg.mesh = bg_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.2, 0.2, 0.2)  # Dark gray
	health_bar_bg.set_surface_override_material(0, bg_material)
	health_bar_container.add_child(health_bar_bg)
	
	# Fill (green bar)
	health_bar_fill = MeshInstance3D.new()
	health_bar_fill.name = "Fill"
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(1.1, 0.12, 0.06)
	health_bar_fill.mesh = fill_mesh
	health_bar_fill.position.z = 0.02  # Slightly in front
	
	var fill_material = StandardMaterial3D.new()
	fill_material.albedo_color = Color.GREEN
	health_bar_fill.set_surface_override_material(0, fill_material)
	health_bar_container.add_child(health_bar_fill)
	
	# Move health label above the bar
	if health_label:
		health_label.position.y = 2.4

func _physics_process(delta):
	if is_dead:
		return
	
	if player == null or not is_instance_valid(player):
		return
	
	if nav_agent: 
		nav_agent.target_position = player.global_position
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_range: 
		move_toward_player(delta)
	else:
		if can_attack:
			attack_player()
	
	look_at_player()
	
	# Make health bar face camera
	face_health_bar_to_camera()

func face_health_bar_to_camera():
	var camera = get_viewport().get_camera_3d()
	if camera and health_bar_container:
		# Make health bar face camera (billboard effect)
		var look_pos = camera.global_position
		look_pos.y = health_bar_container.global_position.y
		health_bar_container.look_at(look_pos)
		health_bar_container.rotate_y(PI)  # Flip to face correctly

func move_toward_player(delta):
	if nav_agent == null:
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
	else: 
		if nav_agent.is_navigation_finished():
			velocity = Vector3.ZERO
			return
		
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
	look_at(look_pos)

func attack_player():
	can_attack = false
	print("Enemy attacks player!")
	
	if player.has_method("take_damage"):
		player.take_damage(damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: float):
	if is_dead:
		return
	
	current_health -= amount
	print("Enemy took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	update_health_display()
	flash_damage()
	
	if current_health <= 0:
		die()

func update_health_display():
	var health_percent = current_health / max_health
	
	# Update label text
	if health_label:
		health_label.text = "%d/%d" % [int(current_health), int(max_health)]
		
		# Change label color based on health
		if health_percent > 0.6:
			health_label.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_label.modulate = Color.YELLOW
		else:
			health_label.modulate = Color.RED
	
	# Update health bar fill
	if health_bar_fill:
		# Scale the fill bar based on health percentage
		health_bar_fill.scale.x = health_percent
		
		# Move fill bar to stay aligned left
		health_bar_fill.position.x = -(1.1 * (1 - health_percent)) / 2
		
		# Change fill color based on health
		var mat = health_bar_fill.get_surface_override_material(0)
		if mat:
			if health_percent > 0.6:
				mat.albedo_color = Color.GREEN
			elif health_percent > 0.3:
				mat.albedo_color = Color.YELLOW
			else:
				mat.albedo_color = Color.RED

func flash_damage():
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			var original_color = mat.albedo_color
			mat.albedo_color = Color.RED
			await get_tree().create_timer(0.1).timeout
			if not is_dead:
				mat.albedo_color = original_color

func die():
	if is_dead:
		return
	
	is_dead = true
	print("Enemy died!")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.enemy_died()
	
	drop_loot()
	enemy_died.emit()
	queue_free()

func drop_loot():
	print("Enemy dropped loot!")
	if player and player.has_method("add_coins"):
		player.add_coins(10)
