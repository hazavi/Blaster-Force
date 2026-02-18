extends Control

var upgrade_manager: Node

# UI References
@onready var coins_label = $TopBar/CoinsPanel/HBoxContainer/CoinsLabel
@onready var weapon_container = $WeaponScroll/WeaponContainer
@onready var back_button = $BackButton

# Preload weapon card
var weapon_card_scene = preload("res://scenes/ui/weapon_card.tscn")
var update_pending: bool = false


func _ready():
	print("=== SHOP SCENE READY ===")
	
	# Verify weapon card loaded
	if weapon_card_scene == null:
		print("❌ ERROR: weapon_card_scene failed to load!")
		return
	else:
		print("✅ weapon_card_scene loaded successfully")
	
	# Verify weapon container exists
	if weapon_container == null:
		print("❌ ERROR: WeaponContainer not found!")
		return
	else:
		print("✅ WeaponContainer found at: ", weapon_container.get_path())
	
	# Get upgrade manager
	upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	
	if upgrade_manager == null:
		print("❌ ERROR: WeaponUpgradeManager not found!")
		print("Make sure it's added to Autoload in Project Settings!")
		return
	
		print("✅ WeaponUpgradeManager found!")
		print("  - Coins: ", upgrade_manager.coins)  # Should show 50 or your collected amount
		print("  - get_coins(): ", upgrade_manager.get_coins())  # Should match above
		print("  - Owned weapons: ", upgrade_manager.get_owned_weapons().size())
	
	# Connect signals
	upgrade_manager.coins_changed.connect(_request_update)
	upgrade_manager.weapon_upgraded.connect(_request_update)
	upgrade_manager.weapon_purchased.connect(_request_update)
	upgrade_manager.weapon_switched.connect(_request_update)
	
	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		print("✅ Back button connected")
	
	# Show mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Initial UI update
	update_ui()

# NEW: Debounced update request
func _request_update():
	if update_pending:
		return
	
	update_pending = true
	call_deferred("_do_update")

func _do_update():
	await get_tree().process_frame
	update_pending = false
	update_ui()
	
func _upgrade_stat(stat: String, popup: AcceptDialog):
	if upgrade_manager.upgrade_stat(stat):
		print("✅ Upgraded ", stat)
		popup.queue_free()
		# Removed: show_upgrade_menu() - UI will update automatically

func update_ui():
	print("\n=== UPDATING SHOP UI ===")
	
	# ✅ FIX: Update coins display with actual coins from upgrade manager
	if coins_label and upgrade_manager:
		coins_label.text = str(upgrade_manager.get_coins())
		print("✅ Updated coins label: ", coins_label.text)
	
	# Clear existing cards
	var old_count = weapon_container.get_child_count()
	for child in weapon_container.get_children():
		child.queue_free()
	print("🗑️ Cleared ", old_count, " old cards")
	
	# Wait one frame for cleanup
	await get_tree().process_frame
	
	# Add ALL owned weapons
	var owned_weapons = upgrade_manager.get_owned_weapons()
	print("📦 Adding ", owned_weapons.size(), " owned weapon cards...")
	
	for i in range(owned_weapons.size()):
		print("  Adding owned weapon ", i, ": ", owned_weapons[i].name)
		add_owned_weapon_card(owned_weapons[i], i)
	
	# Add buyable weapon cards
	print("📦 Adding buyable weapon cards...")
	var added_buyable = 0
	for i in range(upgrade_manager.shop_weapons.size()):
		if not upgrade_manager.shop_weapons[i].owned:
			print("  Adding buyable weapon ", i, ": ", upgrade_manager.shop_weapons[i].name)
			add_buyable_weapon_card(i)
			added_buyable += 1
	
	print("✅ Total cards in container: ", weapon_container.get_child_count())
	print("=== SHOP UI UPDATE COMPLETE ===\n")


func add_owned_weapon_card(weapon_data: Dictionary, weapon_index: int):
	if weapon_card_scene == null:
		print("❌ ERROR: weapon_card_scene is null!")
		return
	
	print("    Instantiating card for: ", weapon_data.name)
	var card = weapon_card_scene.instantiate()
	
	if card == null:
		print("❌ ERROR: Failed to instantiate card!")
		return
	
	weapon_container.add_child(card)
	print("    ✅ Card added to container")
	
	var is_active = (weapon_index == upgrade_manager.get_active_weapon_index())
	print("    Is active: ", is_active)
	
	# Setup card
	if card.has_method("setup_owned"):
		card.setup_owned(weapon_data, weapon_index, is_active)
		print("    ✅ Card setup complete")
	else:
		print("❌ ERROR: Card doesn't have setup_owned method!")
	
	# FIX: Use lambda to convert 2 parameters to 1
	card.upgrade_pressed.connect(func(_weapon_idx: int, _level: int): 
		_on_upgrade_weapon(weapon_index)
	)
	
	card.equip_pressed.connect(func(_weapon_idx: int): 
		_on_equip_weapon(weapon_index)
	)
	
	# Style based on active/inactive
	var style = StyleBoxFlat.new()
	if is_active:
		style.bg_color = Color(0.15, 0.3, 0.15, 0.95)
		style.border_color = Color(0.3, 1.0, 0.3)
		style.set_border_width_all(5)
		style.shadow_size = 5
		style.shadow_color = Color(0.3, 1.0, 0.3, 0.4)
	else:
		style.bg_color = Color(0.1, 0.15, 0.1, 0.95)
		style.border_color = Color(0.2, 0.5, 0.2)
		style.set_border_width_all(5)
	
	style.set_corner_radius_all(15)
	card.add_theme_stylebox_override("panel", style)


func add_buyable_weapon_card(shop_index: int):
	if weapon_card_scene == null:
		print("❌ ERROR: weapon_card_scene is null!")
		return
	
	var weapon = upgrade_manager.shop_weapons[shop_index]
	print("    Instantiating buyable card for: ", weapon.name)
	
	var card = weapon_card_scene.instantiate()
	
	if card == null:
		print("❌ ERROR: Failed to instantiate buyable card!")
		return
	
	weapon_container.add_child(card)
	print("    ✅ Buyable card added to container")
	
	# Setup card
	if card.has_method("setup_buyable"):
		card.setup_buyable(weapon, shop_index)
		print("    ✅ Buyable card setup complete")
	else:
		print("❌ ERROR: Card doesn't have setup_buyable method!")
	
	# FIX: Use lambda
	card.buy_pressed.connect(func(_idx: int): 
		_on_buy_weapon(shop_index)
	)
	
	# Style as buyable (gold border)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.95)
	style.border_color = Color(1.0, 0.84, 0.0)
	style.set_border_width_all(5)
	style.set_corner_radius_all(15)
	style.shadow_size = 10
	card.add_theme_stylebox_override("panel", style)


func _on_upgrade_weapon(weapon_index: int, current_level: int = 0):
	print("Upgrade weapon at index: ", weapon_index, " (level: ", current_level, ")")
	
	# Make sure this weapon is active
	upgrade_manager.switch_weapon(weapon_index)
	
	# ✅ NEW: Directly upgrade all stats (no popup!)
	if upgrade_manager.upgrade_all_stats():
		print("✅ All stats upgraded!")
	else:
		print("❌ Not enough coins!")


func _on_equip_weapon(weapon_index: int):
	print("Equipping weapon at index: ", weapon_index)
	upgrade_manager.switch_weapon(weapon_index)


func show_upgrade_menu():
	var popup = AcceptDialog.new()
	popup.title = "Choose Upgrade"
	popup.dialog_text = "Select stat to upgrade:"
	popup.dialog_hide_on_ok = false
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var stats = [
		{"name": "damage", "icon": "💥", "label": "Damage"},
		{"name": "fire_rate", "icon": "⚡", "label": "Fire Rate"},
		{"name": "ammo", "icon": "🔫", "label": "Ammo"},
		{"name": "range", "icon": "🎯", "label": "Range"}
	]
	
	for stat in stats:
		var btn = Button.new()
		var cost = upgrade_manager.get_upgrade_cost(stat.name)
		var level = upgrade_manager.get_upgrade_level(stat.name)
		var value = upgrade_manager.get_stat_value(stat.name)
		
		var value_str = ""
		if stat.name == "fire_rate":
			value_str = "%.2fs" % value
		elif stat.name == "range":
			value_str = "%.1fm" % value
		else:
			value_str = str(int(value))
		
		btn.text = "%s %s Lv.%d (%s) - Cost: %d Coins" % [stat.icon, stat.label, level, value_str, cost]
		btn.custom_minimum_size.y = 50
		btn.disabled = not upgrade_manager.can_afford_upgrade(stat.name)
		btn.pressed.connect(_upgrade_stat.bind(stat.name, popup))
		vbox.add_child(btn)
	
	popup.add_child(vbox)
	add_child(popup)
	popup.popup_centered(Vector2i(500, 400))

func _on_buy_weapon(shop_index: int):
	print("Attempting to buy weapon at index: ", shop_index)
	if upgrade_manager.buy_weapon(shop_index):
		print("✅ Weapon purchased!")


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
