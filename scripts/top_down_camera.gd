extends Camera3D

# ============================================
# TOP-DOWN CAMERA
# Follows the player from above! 
# ============================================

# === SETTINGS ===
@export var height: float = 13.0       # How high above player
@export var offset_z: float = 5.0      # How far back
@export var look_angle: float = -60.0  # Angle looking down (degrees)
@export var follow_speed: float = 8.0  # How smooth the following is

# === STATE ===
var target: Node3D = null

# ============================================
# READY
# ============================================
func _ready() -> void:
	# Find the player
	await get_tree().process_frame  # Wait one frame
	target = get_tree(). get_first_node_in_group("player")
	
	if target:
		print("Camera found player!")
		# Set initial position
		global_position = target. global_position + Vector3(0, height, offset_z)
	else:
		print("Camera: No player found!")
	
	# Set rotation to look down
	rotation_degrees. x = look_angle

# ============================================
# PROCESS - Every frame
# ============================================
func _process(delta: float) -> void:
	if target == null:
		return
	
	# Calculate target position
	var target_position = target.global_position + Vector3(0, height, offset_z)
	
	# Smoothly move camera
	global_position = global_position.lerp(target_position, follow_speed * delta)
