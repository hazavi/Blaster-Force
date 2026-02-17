extends Control

# ============================================
# PAUSE MENU
# ============================================

var resume_button: Button = null
var restart_button: Button = null
var menu_button: Button = null


func _ready():
	# Allow processing while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Find buttons dynamically
	find_ui_nodes()
	
	# Connect signals if buttons found
	if resume_button:
		resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
		resume_button.pressed.connect(_on_resume_pressed)
	else:
		print("ERROR: ResumeButton not found!")
	
	if restart_button:
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
		restart_button.pressed.connect(_on_restart_pressed)
	else:
		print("ERROR: RestartButton not found!")
	
	if menu_button:
		menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_button.pressed.connect(_on_menu_pressed)
	else:
		print("ERROR: MenuButton not found!")
	
	# Pause the game
	get_tree().paused = true
	
	# Show cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func find_ui_nodes():
	# Try multiple possible paths for each button
	resume_button = try_get_node([
		"Panel/Content/ButtonContainer/ResumeButton",
		"VBoxContainer/ButtonContainer/ResumeButton",
		"VBoxContainer/ResumeButton",
		"ResumeButton"
	])
	
	restart_button = try_get_node([
		"Panel/Content/ButtonContainer/RestartButton",
		"VBoxContainer/ButtonContainer/RestartButton",
		"VBoxContainer/RestartButton",
		"RestartButton"
	])
	
	menu_button = try_get_node([
		"Panel/Content/ButtonContainer/MenuButton",
		"VBoxContainer/ButtonContainer/MenuButton",
		"VBoxContainer/MenuButton",
		"MenuButton"
	])
	
	print("=== PAUSE MENU NODES ===")
	print("ResumeButton: ", resume_button != null)
	print("RestartButton: ", restart_button != null)
	print("MenuButton: ", menu_button != null)
	print("========================")


func try_get_node(paths: Array) -> Node:
	for path in paths:
		var node = get_node_or_null(path)
		if node:
			print("  Found node at: ", path)
			return node
	return null


func _on_resume_pressed():
	resume_game()


func _on_restart_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()


func _on_menu_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func resume_game():
	get_tree().paused = false
	queue_free()


# Handle ESC key to close menu
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		resume_game()
