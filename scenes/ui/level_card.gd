extends PanelContainer

@onready var level_number_label = $Content/LevelNumber
@onready var status_label = $Content/Status
@onready var play_button = $Content/PlayButton

var level_number: int = 1
var is_unlocked: bool = false
var is_completed: bool = false

signal level_selected(level_num: int)


func setup(level_num: int, unlocked: bool, completed: bool):
	level_number = level_num
	is_unlocked = unlocked
	is_completed = completed
	
	level_number_label.text = "LEVEL %d" % level_number
	
	if completed:
		status_label.text = "✅ COMPLETED"
		status_label.modulate = Color.GREEN
		play_button.text = "REPLAY"
		play_button.disabled = false
	elif unlocked:
		status_label.text = "🔓 UNLOCKED"
		status_label.modulate = Color.YELLOW
		play_button.text = "PLAY"
		play_button.disabled = false
	else:
		status_label.text = "🔒 LOCKED"
		status_label.modulate = Color.GRAY
		play_button.text = "LOCKED"
		play_button.disabled = true
	
	# Style card based on status
	var style = StyleBoxFlat.new()
	if completed:
		style.bg_color = Color(0.1, 0.3, 0.1, 0.95)
		style.border_color = Color.GREEN
	elif unlocked:
		style.bg_color = Color(0.2, 0.2, 0.1, 0.95)
		style.border_color = Color.YELLOW
	else:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
		style.border_color = Color.GRAY
	
	style.set_border_width_all(3)
	style.set_corner_radius_all(15)
	add_theme_stylebox_override("panel", style)


func _ready():
	if play_button:
		play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed():
	level_selected.emit(level_number)
