extends CharacterBody3D

# ============================================
# SHOOTER - Ranged magic attacker!
# ============================================

# Stats
@export var max_health: float = 100
@export var speed: float = 5.0
@export var damage: float = 15.0
@export var attack_range: float = 15 # Long range!
@export var attack_cooldown: float = 0.2
@export var detection_range: float = 15.0
@export var preferred_distance: float = 5.0  # Keeps this distance from player

# State
var current_health: float
var player: Node3D = null
var can_attack: bool = true
var is_dead: bool = false
var is_attacking: bool = false
var current_anim: String = ""
var player_in_range: bool = false

# References
var nav_agent: NavigationAgent3D = null
var health_label: Label3D = null
var anim_player: AnimationPlayer = null
var body: Node3D = null
var detection_area: Area3D = null
var wand: Node3D = null  # The wand/staff

# Bullet
var bullet_scene: PackedScene = null

# Health bar
var health_bar_container: Node3D
var health_bar_fill: MeshInstance3D

signal enemy_died


func _ready():
	add_to_group("enemies")
	current_health = max_health
	
	find_nodes()
	setup_detection_area()
	create_health_bar()
	load_bullet()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if nav_agent:
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = 1.0
		nav_agent.max_speed = speed
	
	update_health_display()
	play_anim("Shooter/Idle")
	
	if anim_player:
		print("=== SHOOTER ANIMATIONS ===")
		for anim in anim_player.get_animation_list():
			print("  ", anim)
		print("==========================")
	
	print("Shooter spawned! HP: ", current_health, " Range: ", attack_range)


func find_nodes():
	nav_agent = get_node_or_null("NavigationAgent3D")
	health_label = get_node_or_null("HealthLabel")
	detection_area = get_node_or_null("DetectionArea")
	
	body = get_node_or_null("Body")
	if body == null:
		for child in get_children():
			if child is Node3D and child.name not in ["NavigationAgent3D", "HealthLabel", "CollisionShape3D", "DetectionArea", "Marker3D"]:
				body = child
				break
	
	anim_player = find_child("AnimationPlayer", true, false)
	
	# Find the wand
	wand = find_child("Wand", true, false)
	
	print("=== SHOOTER NODES ===")
	print("Body: ", body != null)
	print("AnimPlayer: ", anim_player != null)
	print("NavAgent: ", nav_agent != null)
	print("DetectionArea: ", detection_area != null)
	print("Wand: ", wand != null)
	print("=====================")


func load_bullet():
	# Try to load enemy bullet scene
	if ResourceLoader.exists("res://scenes/effects/enemy_bullet.tscn"):
		bullet_scene = load("res://scenes/effects/enemy_bullet.tscn")
		print("Shooter: Bullet loaded!")
	else:
		print("Shooter: No bullet scene found, will create dynamically")


func setup_detection_area():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
		print("Shooter DetectionArea connected!")


func _on_detection_body_entered(body_node: Node3D):
	if body_node.is_in_group("player"):
		player_in_range = true
		player = body_node
		print("Shooter spotted player!")


func _on_detection_body_exited(body_node: Node3D):
	if body_node.is_in_group("player"):
		player_in_range = false
		print("Player out of shooter range!")


func create_health_bar():
	health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar3D"
	health_bar_container.position.y = 2.5
	add_child(health_bar_container)
	
	var bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(1.2, 0.15, 0.05)
	bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.2, 0.2, 0.2)
	bg.set_surface_override_material(0, bg_mat)
	health_bar_container.add_child(bg)
	
	health_bar_fill = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(1.1, 0.12, 0.06)
	health_bar_fill.mesh = fill_mesh
	health_bar_fill.position.z = 0.02
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color.PURPLE  # Purple for magic shooter!
	health_bar_fill.set_surface_override_material(0, fill_mat)
	health_bar_container.add_child(health_bar_fill)
	
	if health_label:
		health_label.position.y = 2.8


func _physics_process(delta):
	if is_dead:
		return
	
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			play_anim("Shooter/Idle")
			return
	
	# Check detection
	var should_act = player_in_range
	if not should_act and detection_area == null:
		var dist = global_position.distance_to(player.global_position)
		should_act = dist <= detection_range
	
	if is_attacking:
		velocity = Vector3.ZERO
		move_and_slide()
		face_health_bar_to_camera()
		return
	
	if should_act:
		var distance = global_position.distance_to(player.global_position)
		
		if nav_agent:
			nav_agent.target_position = player.global_position
		
		# Shooter keeps distance!
		if distance < preferred_distance - 1.0:
			# Too close - back away!
			move_away_from_player(delta)
			play_anim("Shooter/Running")
		elif distance > preferred_distance + 2.0:
			# Too far - move closer
			move_toward_player(delta)
			play_anim("Shooter/Running")
		else:
			# Perfect distance - SHOOT!
			velocity = Vector3.ZERO
			if can_attack:
				attack_player()
			else:
				play_anim("Shooter/Idle")
		
		look_at_player()
	else:
		velocity = Vector3.ZERO
		play_anim("Shooter/Idle")
	
	move_and_slide()
	face_health_bar_to_camera()


func move_toward_player(delta):
	var direction: Vector3
	
	if nav_agent and not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		direction = (next_pos - global_position).normalized()
	else:
		direction = (player.global_position - global_position).normalized()
	
	direction.y = 0
	
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	
	if not is_on_floor():
		velocity.y -= 20 * delta
	else:
		velocity.y = 0


func move_away_from_player(delta):
	# Move AWAY from player
	var direction = (global_position - player.global_position).normalized()
	direction.y = 0
	
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	
	if not is_on_floor():
		velocity.y -= 20 * delta
	else:
		velocity.y = 0


func look_at_player():
	if player == null:
		return
	
	var target_pos = player.global_position
	target_pos.y = global_position.y
	var direction = (target_pos - global_position)
	direction.y = 0
	
	if direction.length() > 0.1:
		direction = direction.normalized()
		var target_angle = atan2(direction.x, direction.z)
		if body:
			body.rotation.y = lerp_angle(body.rotation.y, target_angle, 0.15)
		else:
			rotation.y = lerp_angle(rotation.y, target_angle, 0.15)


func face_health_bar_to_camera():
	var camera = get_viewport().get_camera_3d()
	if camera and health_bar_container:
		var look_pos = camera.global_position
		look_pos.y = health_bar_container.global_position.y
		health_bar_container.look_at(look_pos)
		health_bar_container.rotate_y(PI)


func attack_player():
	if is_attacking:
		return
	
	can_attack = false
	is_attacking = true
	
	# Play shoot animation
	play_anim("Shooter/Shoot")
	
	# Wait for animation wind-up
	await get_tree().create_timer(0.5).timeout
	
	# Shoot!
	shoot_at_player()
	
	await get_tree().create_timer(0.5).timeout
	
	is_attacking = false
	
	# Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func shoot_at_player():
	if player == null or not is_instance_valid(player):
		return
	
	print("Shooter fires!")
	
	# Get muzzle position (from wand or default)
	var muzzle_pos: Vector3
	if wand:
		muzzle_pos = wand.global_position
	else:
		muzzle_pos = global_position + Vector3(0, 1.5, 0)
	
	# Calculate direction to player
	var target_pos = player.global_position + Vector3(0, 1.0, 0)  # Aim at player center
	var direction = (target_pos - muzzle_pos).normalized()
	
	# Create bullet
	var bullet: Node3D
	
	if bullet_scene:
		bullet = bullet_scene.instantiate()
	else:
		# Create bullet dynamically
		bullet = create_capsule_bullet()
	
	get_tree().root.add_child(bullet)
	bullet.global_position = muzzle_pos
	
	# Setup bullet
	if bullet.has_method("setup"):
		bullet.setup(damage, 20.0, direction)
	else:
		# Manual setup if no method
		bullet.set("damage", damage)
		bullet.set("speed", 20.0)
		bullet.set("direction", direction)


func create_capsule_bullet() -> Node3D:
	"""Create a capsule-shaped bullet dynamically"""
	var bullet = Area3D.new()
	bullet.name = "ShooterBullet"
	
	# Add mesh (capsule shape)
	var mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.1
	capsule.height = 0.5
	mesh.mesh = capsule
	mesh.rotation.x = deg_to_rad(90)  # Point forward
	
	# Material - glowing purple
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 1.0)  # Purple
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.2, 1.0)
	mat.emission_energy_multiplier = 2.0
	mesh.set_surface_override_material(0, mat)
	bullet.add_child(mesh)
	
	# Add collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.1
	shape.height = 0.5
	collision.shape = shape
	collision.rotation.x = deg_to_rad(90)
	bullet.add_child(collision)
	
	# Add script behavior
	var script = GDScript.new()
	script.source_code = """
extends Area3D

var speed = 20.0
var damage = 15.0
var direction = Vector3.FORWARD

func _ready():
	body_entered.connect(_on_hit)
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func setup(new_damage, new_speed, new_direction):
	damage = new_damage
	speed = new_speed
	direction = new_direction.normalized()

func _on_hit(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("enemies"):
		queue_free()
"""
	bullet.set_script(script)
	
	return bullet


func play_anim(anim_name: String):
	if anim_player == null:
		return
	
	if is_attacking and anim_name != "Shooter/Shoot" and anim_name != "Shooter/Death":
		return
	
	if current_anim == anim_name:
		return
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		current_anim = anim_name
		return
	
	var short_name = anim_name.split("/")[-1]
	if anim_player.has_animation(short_name):
		anim_player.play(short_name)
		current_anim = short_name
		return
	
	print("Shooter animation not found: ", anim_name)


func take_damage(amount: float):
	if is_dead:
		return
	
	current_health -= amount
	print("Shooter took ", amount, " damage! HP: ", current_health, "/", max_health)
	
	update_health_display()
	
	if not is_attacking:
		play_anim("Shooter/Hit")
		await get_tree().create_timer(0.3).timeout
		if not is_dead and not is_attacking:
			play_anim("Shooter/Idle")
	
	if current_health <= 0:
		die()


func update_health_display():
	var health_percent = clamp(current_health / max_health, 0.0, 1.0)
	
	if health_label:
		health_label.text = "%d/%d" % [int(max(current_health, 0)), int(max_health)]
		if health_percent > 0.6:
			health_label.modulate = Color.GREEN
		elif health_percent > 0.3:
			health_label.modulate = Color.YELLOW
		else:
			health_label.modulate = Color.RED
	
	if health_bar_fill:
		health_bar_fill.scale.x = max(health_percent, 0.01)
		health_bar_fill.position.x = -(1.1 * (1.0 - health_percent)) / 2.0
		var mat = health_bar_fill.get_surface_override_material(0)
		if mat:
			if health_percent > 0.6:
				mat.albedo_color = Color.GREEN
			elif health_percent > 0.3:
				mat.albedo_color = Color.YELLOW
			else:
				mat.albedo_color = Color.RED


func die():
	if is_dead:
		return
	
	is_dead = true
	is_attacking = false
	can_attack = false
	velocity = Vector3.ZERO
	
	print("Shooter died!")
	
	play_anim("Shooter/Death")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.enemy_died()
	
	drop_loot()
	enemy_died.emit()
	
	if anim_player and anim_player.has_animation("Shooter/Death"):
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(1.5).timeout
	
	queue_free()


func drop_loot():
	print("Shooter dropped loot!")
	
	var drop_position = global_position + Vector3(0, 0.5, 0)
	
	var coin_scene = load("res://scenes/pickups/coin.tscn")
	var health_scene = load("res://scenes/pickups/health_pickup.tscn")
	
	# Drop medium amount of coins
	if coin_scene:
		var coin_count = randi_range(2, 3)
		for i in range(coin_count):
			var coin = coin_scene.instantiate()
			get_tree().root.add_child(coin)
			
			var scatter = Vector3(
				randf_range(-0.7, 0.7),
				randf_range(0.2, 0.5),
				randf_range(-0.7, 0.7)
			)
			coin.global_position = drop_position + scatter
			coin.value = randi_range(4, 7)
	
	# 30% chance to drop health
	if health_scene and randf() < 0.3:
		var health = health_scene.instantiate()
		get_tree().root.add_child(health)
		health.global_position = drop_position + Vector3(0, 0.3, 0)
		health.heal_amount = 20
