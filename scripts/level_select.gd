extends Control

@onready var level_container = $ScrollContainer/LevelContainer
@onready var back_button = $BackButton

var level_button_scene = preload("res://scenes/ui/level_button.tscn")

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	populate_levels()

func populate_levels():
	# Clear existing buttons
	for child in level_container.get_children():
		child.queue_free()
	
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	if not level_progress:
		return
	
	# Create button for each level
	for i in range(1, level_progress.TOTAL_LEVELS + 1):
		var button = create_level_button(i)
		level_container.add_child(button)

func create_level_button(level_num: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 100)
	
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	
	var is_unlocked = level_progress.is_level_unlocked(level_num)
	var is_completed = level_progress.is_level_completed(level_num)
	
	# Set button text
	if is_completed:
		button.text = "✅ LEVEL %d\nCOMPLETED" % level_num
	elif is_unlocked:
		button.text = "🔓 LEVEL %d\nPLAY" % level_num
	else:
		button.text = "🔒 LEVEL %d\nLOCKED" % level_num
	
	button.disabled = not is_unlocked
	
	# Connect signal
	button.pressed.connect(_on_level_selected.bind(level_num))
	
	# Style
	style_button(button, is_unlocked, is_completed)
	
	return button

func style_button(button: Button, unlocked: bool, completed: bool):
	var style = StyleBoxFlat.new()
	
	if completed:
		style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
		style.border_color = Color(0.3, 1.0, 0.3)
	elif unlocked:
		style.bg_color = Color(0.3, 0.3, 0.5, 0.9)
		style.border_color = Color(0.5, 0.5, 1.0)
	else:
		style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
		style.border_color = Color(0.4, 0.4, 0.4)
	
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	
	button.add_theme_stylebox_override("normal", style)

func _on_level_selected(level_num: int):
	var level_progress = get_node_or_null("/root/LevelProgressManager")
	if level_progress:
		level_progress.load_level(level_num)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
