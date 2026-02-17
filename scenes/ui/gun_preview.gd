extends Node3D

@export var rotation_speed: float = 50.0
@onready var gun_slot = $GunSlot

var current_gun_model: Node3D = null
var is_loading: bool = false

func _process(delta):
	if gun_slot:
		gun_slot.rotate_y(deg_to_rad(rotation_speed * delta))


func set_gun_model(gun_path: String):
	"""Load a gun model from file path"""
	# Prevent multiple simultaneous loads
	if is_loading:
		await get_tree().process_frame
		return
	
	is_loading = true
	print("🔫 [%s] Loading: %s" % [name, gun_path])
	
	# Clear existing gun FIRST
	clear_gun()
	
	# Wait one frame to ensure cleanup
	await get_tree().process_frame
	
	if gun_path == "" or not ResourceLoader.exists(gun_path):
		print("❌ [%s] Gun not found: %s" % [name, gun_path])
		create_placeholder()
		is_loading = false
		return
	
	# Load new gun model - IMPORTANT: Create a NEW instance each time
	var gun_resource = load(gun_path)
	if gun_resource:
		current_gun_model = gun_resource.instantiate()
		gun_slot.add_child(current_gun_model)
		
		# Scale and position
		current_gun_model.scale = Vector3(2.0, 2.0, 2.0)
		current_gun_model.position = Vector3(0, -0.1, 0)
		
		# Disable shadows
		disable_shadows_recursive(current_gun_model)
		
		print("✅ [%s] Loaded: %s" % [name, gun_path])
	else:
		print("❌ [%s] Failed to load: %s" % [name, gun_path])
		create_placeholder()
	
	is_loading = false


func disable_shadows_recursive(node: Node):
	"""Recursively disable shadow casting on all MeshInstance3D nodes"""
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	for child in node.get_children():
		disable_shadows_recursive(child)


func set_gun_by_name(weapon_name: String):
	"""Load gun model by weapon name"""
	print("🎯 [%s] Loading gun for weapon: %s" % [name, weapon_name])
	var gun_path = get_gun_path_from_name(weapon_name)
	await set_gun_model(gun_path)


func get_gun_path_from_name(weapon_name: String) -> String:
	"""Map weapon name to model path"""
	var name_lower = weapon_name.to_lower()
	
	match name_lower:
		"blaster-c":
			return "res://assets/models/guns/FBX/blaster-c.fbx"
		"blaster-g":
			return "res://assets/models/guns/FBX/blaster-g.fbx"
		"blaster-q":
			return "res://assets/models/guns/FBX/blaster-q.fbx"
		_:
			print("   ⚠️ No match found for: ", name_lower)
			return ""


func clear_gun():
	"""Remove current gun model"""
	if current_gun_model and is_instance_valid(current_gun_model):
		current_gun_model.queue_free()
		current_gun_model = null
	
	# Clear ALL children in gun_slot
	for child in gun_slot.get_children():
		child.queue_free()


func create_placeholder():
	"""Create a simple box as placeholder"""
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.8, 0.2, 0.3)
	mesh.mesh = box
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mesh.set_surface_override_material(0, mat)
	
	gun_slot.add_child(mesh)
	current_gun_model = mesh
