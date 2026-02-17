extends Area3D

# ============================================
# ENEMY BULLET - Capsule shaped projectile
# ============================================

var speed: float = 20.0
var damage: float = 15.0
var direction: Vector3 = Vector3.FORWARD

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready():
	# Connect hit detection
	body_entered.connect(_on_hit)
	
	# Destroy after 5 seconds
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta):
	# Move bullet
	global_position += direction * speed * delta
	
	# Make bullet face direction of travel
	if direction.length() > 0:
		look_at(global_position + direction)


func setup(new_damage: float, new_speed: float, new_direction: Vector3):
	damage = new_damage
	speed = new_speed
	direction = new_direction.normalized()


func _on_hit(body: Node3D):
	# Hit player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("Bullet hit player for ", damage, " damage!")
		queue_free()
	# Hit wall or obstacle (not enemy)
	elif not body.is_in_group("enemies"):
		queue_free()
