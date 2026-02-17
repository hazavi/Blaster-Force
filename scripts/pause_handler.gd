extends Node

# ============================================
# PAUSE HANDLER - Global pause system
# ============================================

var pause_menu_scene: PackedScene = null
var pause_menu_instance: Control = null


func _ready():
	pause_menu_scene = load("res://scenes/ui/pause_menu.tscn")
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event):
	# Only allow pausing during gameplay
	if event.is_action_pressed("ui_cancel"):
		var current_scene = get_tree().current_scene
		
		# Don't pause if in menu
		if current_scene.name in ["MainMenu", "GameOver", "LevelComplete"]:
			return
		
		# Don't pause if player is dead
		var player = get_tree().get_first_node_in_group("player")
		if player and player.is_dead:
			return
		
		toggle_pause()


func toggle_pause():
	if get_tree().paused:
		# Already paused, let menu handle it
		return
	else:
		# Show pause menu
		show_pause_menu()


func show_pause_menu():
	if pause_menu_instance:
		return  # Already showing
	
	pause_menu_instance = pause_menu_scene.instantiate()
	get_tree().root.add_child(pause_menu_instance)
	
	# Connect to when it's freed
	pause_menu_instance.tree_exited.connect(_on_pause_menu_closed)


func _on_pause_menu_closed():
	pause_menu_instance = null
