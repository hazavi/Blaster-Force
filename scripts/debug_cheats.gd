extends Node

# ============================================
# DEBUG CHEATS - For Testing Only!
# ============================================

var cheats_enabled: bool = true  # Set to false in production


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("🎮 DEBUG CHEATS LOADED!")
	print("Press F1 to add 100 coins")
	print("Press F2 to add 1000 coins")
	print("Press F3 to reset coins to 50")
	print("Press F4 to set coins to 10000")


func _input(event):
	if not cheats_enabled:
		return
	
	# F1 - Add 100 coins
	if event.is_action_pressed("ui_text_completion_accept"):  # F1
		add_coins(100)
	
	# F2 - Add 1000 coins
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		add_coins(1000)
	
	# F3 - Reset to 50
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		set_coins(50)
	
	# F4 - Set to 10000
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		set_coins(10000)
	
	# F5 - Print current coins
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		print_coins()


func add_coins(amount: int):
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if upgrade_manager:
		upgrade_manager.add_coins(amount)
		print("💰 CHEAT: Added ", amount, " coins! Total: ", upgrade_manager.get_coins())
	else:
		print("❌ WeaponUpgradeManager not found!")


func set_coins(amount: int):
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if upgrade_manager:
		upgrade_manager.coins = amount
		upgrade_manager.coins_changed.emit()
		print("💰 CHEAT: Set coins to ", amount)
		
		# Save immediately
		var save_manager = get_node_or_null("/root/SaveManager")
		if save_manager:
			save_manager.save_game()
	else:
		print("❌ WeaponUpgradeManager not found!")


func print_coins():
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if upgrade_manager:
		print("💰 Current coins: ", upgrade_manager.get_coins())
	else:
		print("❌ WeaponUpgradeManager not found!")
