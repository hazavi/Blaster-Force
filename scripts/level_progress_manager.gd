extends Node

const TOTAL_LEVELS = 3

var levels_unlocked: int = 1
var current_level: int = 1
var levels_completed: Array[bool] = [false, false, false]

signal level_unlocked(level_number: int)
signal level_completed_signal(level_number: int)


func _ready():
	load_progress()
	print("=== LEVEL PROGRESS MANAGER READY ===")
	print("Levels unlocked: ", levels_unlocked)
	print("Current level: ", current_level)
	print("Levels completed: ", levels_completed)


func complete_level(level_number: int):
	"""Mark a level as completed and unlock next level"""
	if level_number < 1 or level_number > TOTAL_LEVELS:
		print("❌ Invalid level number: ", level_number)
		return
	
	# Mark level as completed
	levels_completed[level_number - 1] = true
	
	print("✅ Level ", level_number, " marked as completed!")
	print("   Completed array: ", levels_completed)
	
	# Unlock next level
	if level_number < TOTAL_LEVELS:
		var next_level = level_number + 1
		if next_level > levels_unlocked:
			levels_unlocked = next_level
			level_unlocked.emit(next_level)
			print("🎉 Level ", next_level, " unlocked!")
			print("   Levels unlocked: ", levels_unlocked)
	
	level_completed_signal.emit(level_number)
	
	# ✅ CRITICAL: Save immediately!
	save_progress()
	
	# ✅ Verify save
	await get_tree().process_frame
	print("🔍 Verifying save...")
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		var loaded_data = save_manager.load_game()
		print("   Saved levels_unlocked: ", loaded_data.get("levels_unlocked"))
		print("   Saved levels_completed: ", loaded_data.get("levels_completed"))


func is_level_unlocked(level_number: int) -> bool:
	return level_number <= levels_unlocked


func is_level_completed(level_number: int) -> bool:
	if level_number < 1 or level_number > TOTAL_LEVELS:
		return false
	return levels_completed[level_number - 1]


func get_unlocked_levels() -> int:
	return levels_unlocked


func load_level(level_num: int):
	"""Load a specific level scene"""
	if not is_level_unlocked(level_num):
		print("❌ Level ", level_num, " is locked!")
		return
	
	current_level = level_num
	save_progress()
	
	var level_path = "res://scenes/levels/level_%d.tscn" % level_num
	
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		print("❌ Level file not found: ", level_path)


func reset_progress():
	"""Reset all level progress (for testing)"""
	levels_unlocked = 1
	current_level = 1
	levels_completed = [false, false, false]
	save_progress()
	print("🔄 Progress reset!")


func save_progress():
	"""Save level progress"""
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.save_game()
		print("💾 Level progress saved!")


func load_progress():
	"""Load level progress from save"""
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		print("⚠️ SaveManager not found!")
		return
	
	var save_data = save_manager.load_game()
	
	levels_unlocked = save_data.get("levels_unlocked", 1)
	current_level = save_data.get("current_level", 1)
	
	# ✅ FIX: Properly convert Array to Array[bool]
	var loaded_levels = save_data.get("levels_completed", [false, false, false])
	levels_completed.clear()
	
	for i in range(TOTAL_LEVELS):
		if i < loaded_levels.size():
			levels_completed.append(bool(loaded_levels[i]))
		else:
			levels_completed.append(false)
	
	print("📁 Loaded progress - Unlocked: ", levels_unlocked, ", Completed: ", levels_completed)
