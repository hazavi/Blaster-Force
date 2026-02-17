extends Node3D

# Gun settings
var damage = 20
var fire_rate = 0.3
var bullet_speed = 30
var mag_size = 12
var reload_time = 1.5

# Current states
var current_ammo = 12
var can_shoot = true
var is_reloading = false

# Store the target position
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


func try_shoot(target_position):
	if can_shoot == false:
		return
	
	if is_reloading == true:
		return
	
	if current_ammo <= 0:
		reload()
		return
	
	# Store target for shooting
	last_target_position = target_position
	shoot_at(target_position)


func shoot_at(target_position):
	can_shoot = false
	
	# Create bullet
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Position at muzzle (or player position if muzzle is wrong)
	if muzzle:
		bullet.global_position = muzzle.global_position
	else:
		bullet.global_position = global_position
	
	# IMPORTANT: Calculate direction directly from bullet to target
	# This ignores any rotation issues!
	var direction = (target_position - bullet.global_position).normalized()
	
	# Make sure direction is horizontal (no shooting up/down)
	direction.y = 0
	direction = direction.normalized()
	
	# Setup bullet with correct direction
	bullet.setup(damage, bullet_speed, direction)
	
	# Use ammo
	current_ammo = current_ammo - 1
	ammo_changed.emit()
	
	print("Shot at: ", target_position, " Direction: ", direction)
	
	# Wait for fire rate
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	
	# Auto reload if empty
	if current_ammo <= 0:
		reload()


func reload():
	if is_reloading == true:
		return
	
	if current_ammo == mag_size:
		return
	
	is_reloading = true
	reload_started.emit()
	print("Reloading...")
	
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("play_reload_anim"):
		player.play_reload_anim()
	
	await get_tree().create_timer(reload_time).timeout
	
	current_ammo = mag_size
	is_reloading = false
	ammo_changed.emit()
	reload_finished.emit()
	print("Reload complete!")
