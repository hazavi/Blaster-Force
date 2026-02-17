extends Control

var coins_label: Label = null
var kills_label: Label = null  # NEW
var retry_button: Button = null
var menu_button: Button = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	find_ui_nodes()
	
	if retry_button:
		retry_button.process_mode = Node.PROCESS_MODE_ALWAYS
		retry_button.pressed.connect(_on_retry_pressed)
	
	if menu_button:
		menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_button.pressed.connect(_on_menu_pressed)
	
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	display_stats()


func find_ui_nodes():
	coins_label = try_get_node([
		"Panel/Content/StatsContainer/CoinsLabel",
		"VBoxContainer/CoinsLabel",
		"CoinsLabel"
	])
	
	kills_label = try_get_node([
		"Panel/Content/StatsContainer/KillsLabel",
		"VBoxContainer/KillsLabel",
		"KillsLabel"
	])
	
	retry_button = try_get_node([
		"Panel/Content/ButtonContainer/RetryButton",
		"VBoxContainer/RetryButton",
		"RetryButton"
	])
	
	menu_button = try_get_node([
		"Panel/Content/ButtonContainer/MenuButton",
		"VBoxContainer/MenuButton",
		"MenuButton"
	])


func try_get_node(paths: Array) -> Node:
	for path in paths:
		var node = get_node_or_null(path)
		if node:
			return node
	return null


func display_stats():
	var player = get_tree().get_first_node_in_group("player")
	var game_manager = get_node_or_null("/root/GameManager")
	
	# Coins COLLECTED (not lost!)
	if coins_label:
		if player:
			coins_label.text = "Coins: %d" % player.coins
		else:
			coins_label.text = "Coins: 0"
	
	# Kills
	if kills_label and game_manager:
		kills_label.text = "Kills: %d" % game_manager.get_enemies_killed()


func _on_retry_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()


func _on_menu_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_retry_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()
