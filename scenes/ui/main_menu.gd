extends Control

@onready var play_button = $ButtonContainer/PlayButton
@onready var shop_button = $ButtonContainer/ShopButton
@onready var quit_button = $ButtonContainer/QuitButton

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_pressed():
	print("Opening level select...")
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_shop_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")

func _on_quit_pressed():
	get_tree().quit()
