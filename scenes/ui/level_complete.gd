extends Control

var coins_label: Label = null
var time_label: Label = null
var next_button: Button = null
var menu_button: Button = null


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	find_ui_nodes()
	
	if next_button:
		next_button.process_mode = Node.PROCESS_MODE_ALWAYS
		next_button.pressed.connect(_on_next_level_pressed)
	
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
	
	time_label = try_get_node([
		"Panel/Content/StatsContainer/TimeLabel",
		"VBoxContainer/TimeLabel",
		"TimeLabel"
	])
	
	next_button = try_get_node([
		"Panel/Content/ButtonContainer/NextLevelButton",
		"VBoxContainer/NextLevelButton",
		"NextLevelButton"
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
	
	# Coins
	if coins_label and player:
		coins_label.text = "Coins Collected: %d" % player.coins
	
	# Time
	if time_label and game_manager:
		var time = game_manager.get_level_time()
		time_label.text = "Time: %s" % game_manager.format_time(time)


func _on_next_level_pressed():
	get_tree().paused = false
	queue_free()
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.go_to_next_level()
	else:
		get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")


func _on_menu_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_next_level_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()
