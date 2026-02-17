extends Node

# ============================================
# SAVE MANAGER - Persistent data system
# ============================================

const SAVE_PATH = "user://save_game.json"

var default_data = {
	"coins": 50,  # Starting coins 
	"owned_weapons": [],
	"active_weapon_index": 0,
	"shop_weapons": [],
	"statistics": {
		"total_kills": 0,
		"total_coins_collected": 0,
		"levels_completed": 0
	}
}


func _ready():
	print("=== SAVE MANAGER READY ===")
	print("Save path: ", SAVE_PATH)
	print("Save file exists: ", FileAccess.file_exists(SAVE_PATH))


func save_game() -> bool:
	"""Save current game state to file"""
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	var game_manager = get_node_or_null("/root/GameManager")
	
	if not upgrade_manager:
		print("⚠️ WeaponUpgradeManager not found, cannot save!")
		return false
	
	var save_data = {
		"coins": upgrade_manager.coins,  # Changed from gold
		"owned_weapons": upgrade_manager.owned_weapons.duplicate(true),
		"active_weapon_index": upgrade_manager.active_weapon_index,
		"shop_weapons": upgrade_manager.shop_weapons.duplicate(true),
		"statistics": {
			"total_kills": game_manager.enemies_killed if game_manager else 0,
			"total_coins_collected": upgrade_manager.total_coins_collected,
			"levels_completed": 0
		}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("✅ Game saved! Coins: ", save_data.coins)
		return true
	else:
		print("❌ Failed to save game!")
		return false


func load_game() -> Dictionary:
	"""Load game state from file"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("📁 No save file found, using defaults")
		return default_data.duplicate(true)
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.data
			
			# Migrate old saves (convert "gold" to "coins")
			if data.has("gold") and not data.has("coins"):
				data["coins"] = data["gold"]
				print("🔄 Migrated old save: gold -> coins")
			
			print("✅ Game loaded! Coins: ", data.get("coins", 0))
			return data
		else:
			print("❌ Failed to parse save file! Error: ", json.get_error_message())
			return default_data.duplicate(true)
	else:
		print("❌ Failed to open save file!")
		return default_data.duplicate(true)


func delete_save() -> bool:
	"""Delete save file (reset progress)"""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("🗑️ Save file deleted!")
		return true
	return false


func get_save_path() -> String:
	return SAVE_PATH
