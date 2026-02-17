extends Area3D

# ============================================
# COIN PICKUP - Magnetizes to player
# ============================================

@export var value: int = 1
@export var magnet_range: float = 2.0
@export var magnet_speed: float = 12.0
@export var bob_speed: float = 3.0
@export var bob_height: float = 0.2
@export var spin_speed: float = 3.0

var player: Node3D = null
var start_y: float = 1.0
var time: float = 0.0
var being_collected: bool = false

func _ready():
	# Add to coins group
	add_to_group("coins")
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	start_y = global_position.y
	
	# Create visual if not exists
	if not has_node("MeshInstance3D"):
		create_visual()
	
	# Auto destroy after 30 seconds
	await get_tree().create_timer(30.0).timeout
	if is_instance_valid(self):
		queue_free()


func create_visual():
	# Create coin mesh
	var mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.2
	cylinder.height = 0.05
	mesh.mesh = cylinder
	mesh.name = "MeshInstance3D"
	
	# Gold material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0)  # Gold
	mat.metallic = 1.0
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.84, 0.0)
	mat.emission_energy_multiplier = 0.5
	mesh.set_surface_override_material(0, mat)
	
	add_child(mesh)
	
	# Add collision if not exists
	if not has_node("CollisionShape3D"):
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.3
		col.shape = shape
		add_child(col)


func _physics_process(delta):
	time += delta
	
	# Bob up and down
	if not being_collected:
		global_position.y = start_y + sin(time * bob_speed) * bob_height
	
	# Spin
	rotate_y(delta * spin_speed)
	
	# Magnet toward player
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		if distance < magnet_range:
			being_collected = true
			var direction = (player.global_position - global_position).normalized()
			global_position += direction * magnet_speed * delta
			
			# Speed up as we get closer
			magnet_speed += delta * 25


func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		if body.has_method("add_coins"):
			body.add_coins(value)
			print("Player collected ", value, " coins!")
		
		queue_free()
