extends Control

var coins_label: Label = null
var kills_label: Label = null
var gold_earned_label: Label = null  # NEW
var retry_button: Button = null
var menu_button: Button = null

var coins_earned: int = 0  # NEW


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
	
	# NEW: Try to find gold earned label
	gold_earned_label = try_get_node([
		"Panel/Content/StatsContainer/GoldEarnedLabel",
		"VBoxContainer/GoldEarnedLabel",
		"GoldEarnedLabel"
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
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	
	# Show total coins
	if upgrade_manager and coins_label:
		coins_label.text = "🪙 Total Coins: %d" % upgrade_manager.get_coins()
	
	# Kills
	if kills_label and game_manager:
		kills_label.text = "Kills: %d" % game_manager.get_enemies_killed()
	
	# Gold earned label can show coins saved this run
	if gold_earned_label:
		gold_earned_label.text = "💾 Progress Saved!"


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
