extends Area3D

var speed = 30
var damage = 10
var direction = Vector3. FORWARD


func _ready():
	# Connect hit detection
	body_entered.connect(on_hit)
	
	# Destroy after 3 seconds
	await get_tree().create_timer(3). timeout
	queue_free()


func _physics_process(delta):
	# Move bullet forward
	global_position = global_position + direction * speed * delta


func setup(new_damage, new_speed, new_direction):
	damage = new_damage
	speed = new_speed
	direction = new_direction. normalized()


func on_hit(hit_body):
	# Ignore player
	if hit_body.is_in_group("player"):
		return
	
	# Damage enemy
	if hit_body.has_method("take_damage"):
		hit_body.take_damage(damage)
	
	# Destroy bullet
	queue_free()
