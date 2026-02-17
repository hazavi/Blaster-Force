extends CharacterBody3D

# ============================================
# RUSHER - Fast and aggressive!
# ============================================

# Stats - FAST AND WEAK
@export var max_health: float = 100
@export var speed: float = 10.0  # Very fast!
@export var damage: float = 10.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 0.3  # Fast attacks
@export var detection_range: float = 20.0  # Large detection range

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
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.5
		nav_agent.max_speed = speed
	
	update_health_display()
	play_anim("Rusher/Idle")
	
	if anim_player:
		print("=== RUSHER ANIMATIONS ===")
		for anim in anim_player.get_animation_list():
			print("  ", anim)
		print("=========================")
	
	print("Rusher spawned! HP: ", current_health, " Speed: ", speed)


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
	
	print("=== RUSHER NODES ===")
	print("Body: ", body != null)
	print("AnimPlayer: ", anim_player != null)
	print("NavAgent: ", nav_agent != null)
	print("DetectionArea: ", detection_area != null)
	print("====================")


func setup_detection_area():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
		print("Rusher DetectionArea connected!")


func _on_detection_body_entered(body_node: Node3D):
	if body_node.is_in_group("player"):
		player_in_range = true
		player = body_node
		print("Rusher detected player!")


func _on_detection_body_exited(body_node: Node3D):
	if body_node.is_in_group("player"):
		player_in_range = false
		print("Player escaped rusher!")


func create_health_bar():
	health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar3D"
	health_bar_container.position.y = 2.5
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
	
	if health_label:
		health_label.position.y = 2.8


func _physics_process(delta):
	if is_dead:
		return
	
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			play_anim("Rusher/Idle")
			return
	
	# Check detection
	var should_chase = player_in_range
	if not should_chase and detection_area == null:
		var dist = global_position.distance_to(player.global_position)
		should_chase = dist <= detection_range
	
	if is_attacking:
		velocity = Vector3.ZERO
		move_and_slide()
		face_health_bar_to_camera()
		return
	
	if should_chase:
		var distance = global_position.distance_to(player.global_position)
		
		if nav_agent:
			nav_agent.target_position = player.global_position
		
		if distance <= attack_range:
			velocity = Vector3.ZERO
			if can_attack:
				attack_player()
		else:
			# RUSH toward player!
			move_toward_player(delta)
			play_anim("Rusher/Running")
		
		look_at_player()
	else:
		velocity = Vector3.ZERO
		play_anim("Rusher/Idle")
	
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
		velocity.y -= 25 * delta  # Faster gravity for snappier movement
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
			body.rotation.y = lerp_angle(body.rotation.y, target_angle, 0.25)  # Faster turning
		else:
			rotation.y = lerp_angle(rotation.y, target_angle, 0.25)


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
	
	# Play punch animation
	play_anim("Rusher/Punch")
	
	# Quick punch - deal damage fast!
	await get_tree().create_timer(0.2).timeout
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance <= attack_range + 0.5:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				print("Rusher punches for ", damage, " damage!")
	
	await get_tree().create_timer(0.3).timeout
	
	is_attacking = false
	
	# Short cooldown - rusher attacks fast!
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func play_anim(anim_name: String):
	if anim_player == null:
		return
	
	if is_attacking and anim_name != "Rusher/Punch" and anim_name != "Rusher/Death":
		return
	
	if current_anim == anim_name:
		return
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		current_anim = anim_name
		return
	
	# Try short name
	var short_name = anim_name.split("/")[-1]
	if anim_player.has_animation(short_name):
		anim_player.play(short_name)
		current_anim = short_name
		return
	
	print("Rusher animation not found: ", anim_name)


func take_damage(amount: float):
	if is_dead:
		return
	
	current_health -= amount
	print("Rusher took ", amount, " damage! HP: ", current_health, "/", max_health)
	
	update_health_display()
	
	if not is_attacking:
		play_anim("Rusher/Hit")
		await get_tree().create_timer(0.2).timeout
		if not is_dead and not is_attacking:
			play_anim("Rusher/Idle")
	
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
	
	print("Rusher died!")
	
	play_anim("Rusher/Death")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.enemy_died()
	
	drop_loot()
	enemy_died.emit()
	
	if anim_player and anim_player.has_animation("Rusher/Death"):
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	queue_free()


func drop_loot():
	print("Rusher dropped loot!")
	
	var drop_position = global_position + Vector3(0, 0.5, 0)
	
	var coin_scene = load("res://scenes/pickups/coin.tscn")
	var health_scene = load("res://scenes/pickups/health_pickup.tscn")
	
	# Drop fewer coins (rusher is weaker)
	if coin_scene:
		var coin_count = randi_range(1, 2)
		for i in range(coin_count):
			var coin = coin_scene.instantiate()
			get_tree().root.add_child(coin)
			
			var scatter = Vector3(
				randf_range(-0.5, 0.5),
				randf_range(0.2, 0.5),
				randf_range(-0.5, 0.5)
			)
			coin.global_position = drop_position + scatter
			coin.value = randi_range(2, 5)
	
	# 20% chance to drop health (low chance)
	if health_scene and randf() < 0.2:
		var health = health_scene.instantiate()
		get_tree().root.add_child(health)
		health.global_position = drop_position + Vector3(0, 0.3, 0)
		health.heal_amount = 15
