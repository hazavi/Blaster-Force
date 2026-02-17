extends PanelContainer

# UI References
@onready var weapon_name = $Content/WeaponName
@onready var level_badge = $Content/LevelBadge/HBoxContainer/Label
@onready var damage_label = $Content/StatsContainer/DamageLabel
@onready var fire_rate_label = $Content/StatsContainer/FireRateLabel
@onready var ammo_label = $Content/StatsContainer/AmmoLabel
@onready var range_label = $Content/StatsContainer/RangeLabel
@onready var action_button = $Content/ActionButton
@onready var gun_preview = $Content/GunViewport/SubViewport/GunPreview

var weapon_data: Dictionary
var weapon_index: int = -1
var card_type: String

signal upgrade_pressed(weapon_index: int, current_level: int)
signal equip_pressed(weapon_index: int)
signal buy_pressed(shop_index: int)


func _ready():
	if action_button:
		action_button.pressed.connect(_on_action_pressed)
	
	if gun_preview:
		gun_preview.name = "GunPreview_%d" % get_instance_id()


func setup_owned(data: Dictionary, index: int, is_active: bool):
	weapon_data = data
	weapon_index = index
	card_type = "active" if is_active else "owned"
	
	weapon_name.text = data.name.to_upper()
	
	var total_level = data.get("damage_level", 0) + data.get("fire_rate_level", 0) + data.get("ammo_level", 0) + data.get("range_level", 0)
	level_badge.text = "LEVEL %d" % (total_level + 1)
	level_badge.modulate = Color.GREEN if is_active else Color(0.5, 0.8, 0.5)
	
	damage_label.text = "💥 Damage: %d" % data.get("damage", 0)
	fire_rate_label.text = "⚡ Fire Rate: %.2fs" % data.get("fire_rate", 0.0)
	ammo_label.text = "🔫 Ammo: %d" % data.get("mag_size", 0)
	range_label.text = "🎯 Range: %.1fm" % data.get("range", 0.0)
	
	# Button with price
	if is_active:
		var total_cost = get_total_upgrade_cost()
		action_button.text = "⬆️ UPGRADE - %d Coins" % total_cost
	else:
		action_button.text = "✅ EQUIP"
	
	await load_gun_model(data.name)

func get_total_upgrade_cost() -> int:
	"""Get total cost to upgrade all 4 stats"""
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if not upgrade_manager:
		return 100
	
	return upgrade_manager.get_upgrade_all_cost()

func setup_buyable(data: Dictionary, shop_index: int):
	weapon_data = data
	weapon_index = shop_index
	card_type = "buyable"
	
	weapon_name.text = data.name.to_upper()
	level_badge.text = "NEW!"
	level_badge.modulate = Color.YELLOW
	
	damage_label.text = "💥 Damage: %d" % data.get("damage", 0)
	fire_rate_label.text = "⚡ Fire Rate: %.2fs" % data.get("fire_rate", 0.0)
	ammo_label.text = "🔫 Ammo: %d" % data.get("mag_size", 0)
	range_label.text = "🎯 Range: %.1fm" % data.get("range", 0.0)
	
	action_button.text = "🪙 BUY - %d Coins" % data.get("cost", 0)
	
	await load_gun_model(data.name)


func get_cheapest_upgrade_cost(weapon_data: Dictionary) -> int:
	# This function is no longer used, but keeping for compatibility
	var upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if not upgrade_manager:
		return 50
	
	return upgrade_manager.get_upgrade_all_cost()


func load_gun_model(weapon_name_str: String):
	if gun_preview:
		await gun_preview.set_gun_by_name(weapon_name_str)


func _on_action_pressed():
	if card_type == "active":
		# Get current level (sum of all upgrade levels)
		var total_level = weapon_data.get("damage_level", 0) + weapon_data.get("fire_rate_level", 0) + weapon_data.get("ammo_level", 0) + weapon_data.get("range_level", 0)
		upgrade_pressed.emit(weapon_index, total_level)
	elif card_type == "owned":
		equip_pressed.emit(weapon_index)
	elif card_type == "buyable":
		buy_pressed.emit(weapon_index)
