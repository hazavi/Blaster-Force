extends Control

@onready var level_container = $LevelContainer
@onready var back_button = $BackButton
@onready var title_label = $Title

var level_card_scene = preload("res://scenes/ui/level_card.tscn")


func _ready():
	back_button.pressed.connect(_on_back_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	populate_levels()


func populate_levels():
	# Clear existing placeholder cards
	for child in level_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	if not level_progress:
		print("❌ LevelProgressManager not found!")
		return
	
	# Create card for each level
	for i in range(1, level_progress.TOTAL_LEVELS + 1):
		var unlocked = level_progress.is_level_unlocked(i)
		var completed = level_progress.is_level_completed(i)
		
		var card = level_card_scene.instantiate()
		level_container.add_child(card)
		
		# Setup card
		card.setup(i, unlocked, completed)
		
		# Connect signal
		card.level_selected.connect(_on_level_selected)
		
		print("Added card for Level ", i, " - Unlocked: ", unlocked, ", Completed: ", completed)


func _on_level_selected(level_num: int):
	print("Loading level: ", level_num)
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	if level_progress:
		level_progress.load_level(level_num)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
