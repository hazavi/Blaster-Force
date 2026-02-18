extends CharacterBody3D

@export var speed = 5
@export var shoot_range = 6

# Updated paths for new structure
@onready var body = $Body
@onready var range_indicator = $RangeIndicator
@onready var shoot_range_area = $ShootRange

# NEW: Find gun pivot dynamically
var gun_pivot: Node3D = null
var gun: Node3D = null  # Currently active gun
var anim_player: AnimationPlayer = null

# ✅ NEW: References to all 3 gun models
var gun_blaster_c: Node3D = null
var gun_blaster_g: Node3D = null
var gun_blaster_q: Node3D = null

var max_health = 100
var health = 100
var coins = 0
var current_target = null
var enemies_in_range = []
var is_moving = false
var is_shooting = false
var is_reloading = false
var is_dead = false
var current_anim = ""

signal health_changed
signal coins_changed
signal player_died


func _ready():
	add_to_group("player")
	shoot_range_area.body_entered.connect(_on_enemy_entered)
	shoot_range_area.body_exited.connect(_on_enemy_exited)
	health = max_health
	
	# Find nodes dynamically
	find_nodes()
	
	if anim_player != null:
		print("=== ANIMATIONS ===")
		for anim in anim_player.get_animation_list():
			print(anim)
		print("==================")
		
		if anim_player.has_animation("Player/Spawned"):
			play_anim("Player/Spawned")
			await anim_player.animation_finished
		play_anim("Player/Idle")
	
	print("Player ready!")
	print("GunPivot found: ", gun_pivot != null)
	
	# === APPLY WEAPON UPGRADES ===
	await get_tree().process_frame
	await get_tree().process_frame
	
	# ✅ Load correct gun model from the start
	load_current_weapon()


func find_nodes():
	# Find AnimationPlayer in Body
	anim_player = find_child("AnimationPlayer", true, false)
	if anim_player:
		print("Found AnimationPlayer at: ", anim_player.get_path())
	
	# Find GunPivot (might be deep in skeleton)
	gun_pivot = find_child("GunPivot", true, false)
	if gun_pivot:
		print("Found GunPivot at: ", gun_pivot.get_path())
		
		# ✅ NEW: Find all 3 gun models inside GunPivot
		find_all_guns()


# ✅ NEW: Find all gun models in GunPivot
func find_all_guns():
	if not gun_pivot:
		return
	
	# Find each gun by name
	gun_blaster_c = gun_pivot.find_child("blaster-c", false, false)
	gun_blaster_g = gun_pivot.find_child("blaster-g", false, false)
	gun_blaster_q = gun_pivot.find_child("blaster-q", false, false)
	
	print("📦 Found guns:")
	print("  Blaster-C: ", gun_blaster_c != null)
	print("  Blaster-G: ", gun_blaster_g != null)
	print("  Blaster-Q: ", gun_blaster_q != null)


# ✅ NEW: Load the current weapon's gun model
func load_current_weapon():
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if not upgrade_manager:
		print("⚠️ No WeaponUpgradeManager found!")
		return
	
	var weapon = upgrade_manager.get_current_weapon()
	print("🔫 Loading weapon: ", weapon.name)
	
	# Show/hide correct gun
	set_active_gun(weapon.name)
	
	# Apply stats
	if gun and upgrade_manager:
		upgrade_manager.apply_to_gun(gun)
		print("✅ Weapon upgrades applied: ", weapon.name)
	
	# ✅ Listen for weapon switches
	if not upgrade_manager.weapon_switched.is_connected(_on_weapon_switched):
		upgrade_manager.weapon_switched.connect(_on_weapon_switched)


# ✅ NEW: Show only the active gun, hide others
func set_active_gun(weapon_name: String):
	"""Show the correct gun model, hide the others"""
	if not gun_pivot:
		print("❌ GunPivot not found!")
		return
	
	print("🎯 Activating gun: ", weapon_name)
	
	# Hide all guns first
	if gun_blaster_c:
		gun_blaster_c.visible = false
	if gun_blaster_g:
		gun_blaster_g.visible = false
	if gun_blaster_q:
		gun_blaster_q.visible = false
	
	# Show the correct gun
	match weapon_name:
		"Blaster-C":
			if gun_blaster_c:
				gun_blaster_c.visible = true
				gun = gun_blaster_c
				print("  ✅ SHOWING: Blaster-C")
		"Blaster-G":
			if gun_blaster_g:
				gun_blaster_g.visible = true
				gun = gun_blaster_g
				print("  ✅ SHOWING: Blaster-G")
		"Blaster-Q":
			if gun_blaster_q:
				gun_blaster_q.visible = true
				gun = gun_blaster_q
				print("  ✅ SHOWING: Blaster-Q")
		_:
			print("  ❌ Unknown weapon: ", weapon_name)


# ✅ NEW: Switch gun when weapon changes
func _on_weapon_switched():
	print("🔫 Player: Weapon switched! Changing gun model...")
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if not upgrade_manager:
		return
	
	var weapon = upgrade_manager.get_current_weapon()
	set_active_gun(weapon.name)
	
	# Reapply stats
	if gun:
		upgrade_manager.apply_to_gun(gun)


func _physics_process(delta):
	if is_dead:
		return
	
	handle_movement(delta)
	handle_auto_aim()
	handle_auto_shoot()
	update_animation()


func handle_movement(delta):
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_up", "move_down")
	var direction = Vector3(input_x, 0, input_z)
	
	is_moving = (input_x != 0 or input_z != 0)
	
	if direction.length() > 0:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	if not is_on_floor():
		velocity.y = velocity.y - 20 * delta
	
	move_and_slide()


func handle_auto_aim():
	current_target = find_closest_enemy()
	
	if current_target != null:
		# === ENEMY IN RANGE ===
		
		# 1. Body faces enemy
		var target_pos = current_target.global_position
		target_pos.y = body.global_position.y
		body.look_at(target_pos)
		body.rotation.y += PI
		
		# 2. Gun aims at enemy
		if gun_pivot:
			var gun_target = current_target.global_position
			gun_target.y = gun_pivot.global_position.y
			gun_pivot.look_at(gun_target)
		
		# 3. Red indicator
		set_indicator_color(Color(1, 0.3, 0.3, 0.3))
		
	else:
		# === NO ENEMY ===
		
		if is_moving and body != null:
			var input_x = Input.get_axis("move_left", "move_right")
			var input_z = Input.get_axis("move_up", "move_down")
			var direction = Vector3(input_x, 0, input_z).normalized()
			
			if direction != Vector3.ZERO:
				var look_target = global_position + direction
				look_target.y = body.global_position.y
				body.look_at(look_target)
				body.rotation.y += PI
		
		# Blue indicator
		set_indicator_color(Color(0.4, 0.7, 1, 0.2))


func update_animation():
	if anim_player == null:
		return
	if is_dead:
		return
	if is_reloading:
		return
	
	var new_anim = ""
	
	if is_shooting and current_target != null:
		new_anim = "Player/Shooting"
	elif is_moving:
		new_anim = "Player/Running"
	else:
		new_anim = "Player/Idle"
	
	play_anim(new_anim)


func play_anim(anim_name: String):
	if anim_player == null:
		return
	if current_anim == anim_name:
		return
	if not anim_player.has_animation(anim_name):
		print("WARNING: Animation not found: ", anim_name)
		return
	
	anim_player.play(anim_name)
	current_anim = anim_name


func find_closest_enemy():
	if enemies_in_range.is_empty():
		return null
	
	var closest = null
	var closest_dist = 999999
	
	for enemy in enemies_in_range:
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest


func handle_auto_shoot():
	if current_target != null:
		is_shooting = true
		# Use the currently active gun
		if gun != null and gun.has_method("try_shoot"):
			gun.try_shoot(current_target.global_position)
	else:
		is_shooting = false


func _on_enemy_entered(node):
	if node.is_in_group("enemies"):
		enemies_in_range.append(node)
		print("Enemy in range")


func _on_enemy_exited(node):
	if node in enemies_in_range:
		enemies_in_range.erase(node)
		print("Enemy left range")


func take_damage(amount):
	if is_dead:
		return
	
	health = health - amount
	if health < 0:
		health = 0
	health_changed.emit()
	
	play_anim("Player/Hit_Damage")
	
	if health <= 0:
		die()


func heal(amount):
	health = health + amount
	if health > max_health:
		health = max_health
	health_changed.emit()


func die():
	if is_dead:
		return
	
	is_dead = true
	print("Player died!")
	
	# ✨ Convert coins and SAVE immediately
	convert_coins_to_gold()
	
	# ✅ Ensure save happens before any scene changes
	await get_tree().process_frame
	
	# Play death animation
	if anim_player != null and anim_player.has_animation("Player/Death"):
		play_anim("Player/Death")
		await anim_player.animation_finished
	else:
		# Wait a bit if no animation
		await get_tree().create_timer(1.0).timeout
	
	# Emit signal
	player_died.emit()
	
	# Show game over screen
	print("Loading Game Over screen...")
	
	# Make sure the scene exists
	if ResourceLoader.exists("res://scenes/ui/game_over.tscn"):
		var game_over_scene = load("res://scenes/ui/game_over.tscn")
		var game_over = game_over_scene.instantiate()
		get_tree().root.add_child(game_over)
		print("Game Over UI added!")
	else:
		print("ERROR: Game Over scene not found at res://scenes/ui/game_over.tscn")
		# Fallback: reload scene
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()

func convert_coins_to_gold():
	"""Convert collected coins to permanent saved coins"""
	if coins <= 0:
		return
	
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if upgrade_manager:
		upgrade_manager.add_coins(coins)
		print("🪙 Saved ", coins, " coins! New total: ", upgrade_manager.get_coins())
		
		# ✅ CRITICAL: Save to disk immediately
		var save_manager = get_node_or_null("/root/SaveManager")
		if save_manager:
			save_manager.save_game()
			print("💾 Progress saved to disk!")
		
		coins = 0
		coins_changed.emit()

func add_coins(amount):
	coins = coins + amount
	coins_changed.emit()


func set_indicator_color(new_color):
	if range_indicator == null:
		return
	var mat = range_indicator.get_surface_override_material(0)
	if mat != null:
		mat.albedo_color = new_color
