extends Control

var coins_label: Label = null
var time_label: Label = null
var next_button: Button = null
var menu_button: Button = null

# NEW: Prevent duplicate completion calls
var has_completed: bool = false

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
	
	# ✅ Save coins FIRST
	save_player_coins()
	
	# ✅ Mark level as complete ONCE
	if not has_completed:
		mark_level_complete()
		has_completed = true
	
	# Update UI
	update_next_button()
	display_stats()

func save_player_coins():
	var player = get_tree().get_first_node_in_group("player")
	if not player or player.coins <= 0:
		return
	
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if upgrade_manager:
		upgrade_manager.add_coins(player.coins)
		print("🪙 Level Complete: Saved ", player.coins, " coins!")
		player.coins = 0
		player.coins_changed.emit()

func mark_level_complete():
	var game_manager = get_node_or_null("/root/GameManager")
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	
	if game_manager and level_progress:
		var level_num = game_manager.current_level
		print("🎯 Completing level: ", level_num)
		level_progress.complete_level(level_num)
		print("📊 Levels unlocked: ", level_progress.levels_unlocked)
		print("📊 Levels completed: ", level_progress.levels_completed)

func update_next_button():
	if not next_button:
		return
	
	var game_manager = get_node_or_null("/root/GameManager")
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	
	if game_manager and level_progress:
		var next_level = game_manager.current_level + 1
		
		# Hide next button if this is the last level
		if next_level > level_progress.TOTAL_LEVELS:
			next_button.text = "ALL LEVELS COMPLETE!"
			next_button.disabled = true

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
	var game_manager = get_node_or_null("/root/GameManager")
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	
	if coins_label and upgrade_manager:
		coins_label.text = "🪙 Total Coins: %d" % upgrade_manager.get_coins()
	
	if time_label and game_manager:
		var time = game_manager.get_level_time()
		time_label.text = "Time: %s" % game_manager.format_time(time)

func _on_next_level_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	
func _on_menu_pressed():
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_next_level_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()
