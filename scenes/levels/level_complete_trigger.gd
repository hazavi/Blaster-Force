extends Area3D

# ============================================
# LEVEL COMPLETE TRIGGER
# Shows Level Complete UI when player enters
# ============================================

var is_active: bool = false  # Only works after enemies are dead
var level_complete_shown: bool = false


func _ready():
	# Start DISABLED
	monitoring = false
	monitorable = false
	
	# Connect signal
	body_entered.connect(_on_player_entered)
	
	# Connect to GameManager signal
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.all_enemies_dead.connect(_on_all_enemies_dead)


func _on_all_enemies_dead():
	# Activate the trigger when all enemies are dead
	print("Level Complete trigger ACTIVATED!")
	is_active = true
	monitoring = true
	monitorable = true
	
	# Optional: Make it glow
	make_glow()


func make_glow():
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 1.0, 0.4)  # Green
		mat.emission_enabled = true
		mat.emission = Color(0.5, 1.0, 0.6)
		mat.emission_energy_multiplier = 2.0
		mesh.set_surface_override_material(0, mat)


func _on_player_entered(body: Node3D):
	# Only trigger if active and it's the player
	if is_active and body.is_in_group("player"):
		show_level_complete()


func show_level_complete():
	if level_complete_shown:
		return
	
	level_complete_shown = true
	
	print("Player reached exit! Showing Level Complete...")
	
	# Load Level Complete UI
	if ResourceLoader.exists("res://scenes/ui/level_complete.tscn"):
		var level_complete = load("res://scenes/ui/level_complete.tscn").instantiate()
		get_tree().root.add_child(level_complete)
	else:
		print("ERROR: level_complete.tscn not found!")
