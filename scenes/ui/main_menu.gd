extends Control

# ============================================
# MAIN MENU
# ============================================

@onready var play_button = $ButtonContainer/PlayButton
@onready var shop_button = $ButtonContainer/ShopButton
@onready var quit_button = $ButtonContainer/QuitButton


func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Show mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_play_pressed():
	print("Starting game!")
	# Load first level
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")


func _on_shop_pressed():
	print("Opening shop...")
	# TODO: Load shop scene when created
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")


func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()
