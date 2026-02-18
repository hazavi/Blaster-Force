extends Node3D

# Gun settings (will be set by GunManager)
var damage = 15
var fire_rate = 0.8
var bullet_speed = 30
var mag_size = 12
var reload_time = 1.5

# Current states
var current_ammo = 12
var can_shoot = true
var is_reloading = false
var last_target_position = Vector3.ZERO

# Node references
@onready var muzzle = $Muzzle

# Bullet scene
var bullet_scene = preload("res://scenes/effects/bullet.tscn")

# Signals
signal ammo_changed
signal reload_started
signal reload_finished


func _ready():
	current_ammo = mag_size
	
	# Apply base settings from GunManager
	apply_base_settings()


func apply_base_settings():
	"""Apply base stats for this gun model"""
	# Get the weapon name from parent player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if not upgrade_manager:
		return
	
	var weapon = upgrade_manager.get_current_weapon()
	var base_settings = GunManager.get_gun_settings(weapon.name)
	
	# These are just defaults - upgrades will override
	print("📋 Gun base settings loaded: ", weapon.name)


func try_shoot(target_position):
	if can_shoot == false:
		return
	
	if is_reloading == true:
		return
	
	if current_ammo <= 0:
		reload()
		return
	
	last_target_position = target_position
	shoot_at(target_position)


func shoot_at(target_position):
	can_shoot = false
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	if muzzle:
		bullet.global_position = muzzle.global_position
	else:
		bullet.global_position = global_position
	
	var direction = (target_position - bullet.global_position).normalized()
	direction.y = 0
	direction = direction.normalized()
	
	bullet.setup(damage, bullet_speed, direction)
	
	current_ammo -= 1
	ammo_changed.emit()
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	
	if current_ammo <= 0:
		reload()


func reload():
	if is_reloading:
		return
	
	if current_ammo == mag_size:
		return
	
	is_reloading = true
	reload_started.emit()
	print("Reloading...")
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("play_reload_anim"):
		player.play_reload_anim()
	
	await get_tree().create_timer(reload_time).timeout
	
	current_ammo = mag_size
	is_reloading = false
	ammo_changed.emit()
	reload_finished.emit()
	print("Reload complete!")
