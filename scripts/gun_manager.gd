extends Node

# ============================================
# GUN MANAGER - Handles swapping gun models
# ============================================

# Gun model paths
const GUN_MODELS = {
	"Blaster-C": "res://scenes/guns/blaster-c.tscn",
	"Blaster-G": "res://scenes/guns/blaster-g.tscn",
	"Blaster-Q": "res://scenes/guns/blaster-q.tscn"
}

# Gun settings (separate from models)
const GUN_SETTINGS = {
	"Blaster-C": {
		"damage": 15,
		"fire_rate": 1.0,
		"mag_size": 10,
		"bullet_speed": 30,
		"reload_time": 1.5
	},
	"Blaster-G": {
		"damage": 12,
		"fire_rate": 0.8,
		"mag_size": 30,
		"bullet_speed": 35,
		"reload_time": 2.0
	},
	"Blaster-Q": {
		"damage": 35,
		"fire_rate": 1.5,
		"mag_size": 6,
		"bullet_speed": 40,
		"reload_time": 2.5
	}
}


static func get_gun_path(weapon_name: String) -> String:
	"""Get gun model path from weapon name"""
	if GUN_MODELS.has(weapon_name):
		return GUN_MODELS[weapon_name]
	return GUN_MODELS["Blaster-C"]  # Default


static func get_gun_settings(weapon_name: String) -> Dictionary:
	"""Get gun base settings"""
	if GUN_SETTINGS.has(weapon_name):
		return GUN_SETTINGS[weapon_name].duplicate()
	return GUN_SETTINGS["Blaster-C"].duplicate()  # Default
