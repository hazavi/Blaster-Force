extends Area3D

# ============================================
# HEALTH PICKUP
# ============================================

@export var heal_amount: int = 25
@export var bob_speed: float = 2.5
@export var bob_height: float = 0.3
@export var spin_speed: float = 2.0

var start_y: float = 0.0
var time: float = 0.0


func _ready():
	# Add to pickups group
	add_to_group("health_pickups")
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	start_y = global_position.y
	
	# Create visual if not exists
	if not has_node("MeshInstance3D"):
		create_visual()
		
	if start_y < 0.8:
		start_y = 0.8
		global_position.y = start_y
	# Auto destroy after 30 seconds
	await get_tree().create_timer(30.0).timeout
	if is_instance_valid(self):
		queue_free()


func create_visual():
	# Create plus/cross shape with two boxes
	
	# Horizontal bar
	var mesh_h = MeshInstance3D.new()
	var box_h = BoxMesh.new()
	box_h.size = Vector3(0.4, 0.1, 0.1)
	mesh_h.mesh = box_h
	mesh_h.name = "MeshInstance3D"
	
	# Red glowing material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.2)  # Red
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.3)
	mat.emission_energy_multiplier = 1.0
	mesh_h.set_surface_override_material(0, mat)
	
	add_child(mesh_h)
	
	# Vertical bar
	var mesh_v = MeshInstance3D.new()
	var box_v = BoxMesh.new()
	box_v.size = Vector3(0.1, 0.4, 0.1)
	mesh_v.mesh = box_v
	mesh_v.set_surface_override_material(0, mat)
	
	add_child(mesh_v)
	
	# Add collision if not exists
	if not has_node("CollisionShape3D"):
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.4
		col.shape = shape
		add_child(col)


func _physics_process(delta):
	time += delta
	
	# Bob up and down
	global_position.y = start_y + sin(time * bob_speed) * bob_height
	
	# Spin
	rotate_y(delta * spin_speed)


func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
			print("Player healed for ", heal_amount, " HP!")
		
		queue_free()
