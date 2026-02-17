extends Node

# ============================================
# WEAPON UPGRADE MANAGER - Persistent system
# ============================================

# Currency (COINS ONLY!)
var coins: int = 0  # Changed from gold
var total_coins_collected: int = 0  # Track total earned

# All owned weapons (array of weapon data)
var owned_weapons: Array[Dictionary] = []

# Index of currently equipped weapon
var active_weapon_index: int = 0

# Available weapons to buy in shop
var shop_weapons = [
	{
		"name": "Blaster-G",
		"cost": 250,
		"damage": 15,
		"fire_rate": 0.8,
		"mag_size": 30,
		"range": 8.0,
		"owned": false
	},
	{
		"name": "Blaster-Q",
		"cost": 400,
		"damage": 35,
		"fire_rate": 0.8,
		"mag_size": 6,
		"range": 4.0,
		"owned": false
	}
]

# Upgrade costs (base cost, scales with level)
const UPGRADE_COSTS = {
	"damage": 50,
	"fire_rate": 75,
	"ammo": 40,
	"range": 60
}

# Upgrade increments
const UPGRADE_INCREMENTS = {
	"damage": 1,
	"fire_rate": 0.02,
	"ammo": 2,
	"range": 0.02
}

signal coins_changed  # Changed from gold_changed
signal weapon_upgraded
signal weapon_purchased
signal weapon_switched


func _ready():
	# Load saved data
	load_from_save()
	
	print("=== WEAPON UPGRADE MANAGER READY ===")
	print("Coins: ", coins)
	print("Total Coins Collected: ", total_coins_collected)
	print("Starting Weapon: ", owned_weapons[0].name if owned_weapons.size() > 0 else "None")


func load_from_save():
	"""Load data from SaveManager"""
	var save_manager = get_node_or_null("/root/SaveManager")
	if not save_manager:
		print("⚠️ SaveManager not found, using defaults")
		coins = 50  # Default starting coins
		initialize_default_data()
		return
	
	var save_data = save_manager.load_game()
	
	# Load coins FIRST with fallback
	coins = save_data.get("coins", 50)
	total_coins_collected = save_data.get("statistics", {}).get("total_coins_collected", 0)
	
	# Load owned weapons
	var saved_weapons = save_data.get("owned_weapons", [])
	if saved_weapons.size() > 0:
		owned_weapons.clear()
		for weapon_data in saved_weapons:
			owned_weapons.append(weapon_data.duplicate(true))
	else:
		# First time - add starter weapon only
		initialize_default_data()
	
	# Load active weapon
	active_weapon_index = save_data.get("active_weapon_index", 0)
	
	# Load shop weapons
	var saved_shop = save_data.get("shop_weapons", [])
	if saved_shop.size() == shop_weapons.size():
		for i in range(shop_weapons.size()):
			shop_weapons[i].owned = saved_shop[i].get("owned", false)
	
	print("📁 Loaded: ", owned_weapons.size(), " weapons, ", coins, " coins")


func initialize_default_data():
	"""Set up default starter weapon (DOES NOT TOUCH COINS)"""
	owned_weapons.clear()
	owned_weapons.append({
		"name": "Blaster-C",
		"damage": 15,
		"fire_rate": 1,
		"mag_size": 10,
		"range": 6.0,
		"damage_level": 0,
		"fire_rate_level": 0,
		"ammo_level": 0,
		"range_level": 0
	})

func save_progress():
	"""Save current state"""
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.save_game()


# ============================================
# WEAPON ACCESS
# ============================================

func get_current_weapon() -> Dictionary:
	if active_weapon_index >= 0 and active_weapon_index < owned_weapons.size():
		return owned_weapons[active_weapon_index]
	return owned_weapons[0]


func get_owned_weapons() -> Array[Dictionary]:
	return owned_weapons


func switch_weapon(weapon_index: int):
	if weapon_index >= 0 and weapon_index < owned_weapons.size():
		active_weapon_index = weapon_index
		weapon_switched.emit()
		print("Switched to: ", owned_weapons[weapon_index].name)
		save_progress()
		return true
	return false


func get_active_weapon_index() -> int:
	return active_weapon_index


# ============================================
# UPGRADE FUNCTIONS
# ============================================
func can_afford_upgrade_all() -> bool:
	"""Check if player can afford upgrading all 4 stats"""
	var total_cost = 0
	total_cost += get_upgrade_cost("damage")
	total_cost += get_upgrade_cost("fire_rate")
	total_cost += get_upgrade_cost("ammo")
	total_cost += get_upgrade_cost("range")
	return coins >= total_cost


func upgrade_all_stats() -> bool:
	"""Upgrade all 4 stats at once"""
	if not can_afford_upgrade_all():
		print("❌ Not enough coins to upgrade all stats!")
		return false
	
	var total_cost = 0
	total_cost += get_upgrade_cost("damage")
	total_cost += get_upgrade_cost("fire_rate")
	total_cost += get_upgrade_cost("ammo")
	total_cost += get_upgrade_cost("range")
	
	# Deduct total cost
	coins -= total_cost
	
	var weapon = get_current_weapon()
	
	# Upgrade damage
	weapon.damage += UPGRADE_INCREMENTS.damage
	weapon.damage_level += 1
	
	# Upgrade fire rate (faster = lower number)
	weapon.fire_rate = max(0.05, weapon.fire_rate - UPGRADE_INCREMENTS.fire_rate)
	weapon.fire_rate_level += 1
	
	# Upgrade ammo
	weapon.mag_size += UPGRADE_INCREMENTS.ammo
	weapon.ammo_level += 1
	
	# Upgrade range
	weapon.range += UPGRADE_INCREMENTS.range
	weapon.range_level += 1
	
	coins_changed.emit()
	weapon_upgraded.emit()
	
	print("✅ Upgraded ALL stats! Cost: ", total_cost, " coins")
	
	save_progress()
	return true


func get_upgrade_all_cost() -> int:
	"""Get total cost to upgrade all 4 stats"""
	var total = 0
	total += get_upgrade_cost("damage")
	total += get_upgrade_cost("fire_rate")
	total += get_upgrade_cost("ammo")
	total += get_upgrade_cost("range")
	return total


func can_afford_upgrade(stat_name: String) -> bool:
	var cost = get_upgrade_cost(stat_name)
	return coins >= cost
	
func upgrade_stat(stat_name: String) -> bool:
	if not can_afford_upgrade(stat_name):
		return false
	
	var cost = get_upgrade_cost(stat_name)
	coins -= cost  # Changed from gold
	
	var weapon = get_current_weapon()
	
	match stat_name:
		"damage":
			weapon.damage += UPGRADE_INCREMENTS.damage
			weapon.damage_level += 1
		"fire_rate":
			weapon.fire_rate = max(0.05, weapon.fire_rate - UPGRADE_INCREMENTS.fire_rate)
			weapon.fire_rate_level += 1
		"ammo":
			weapon.mag_size += UPGRADE_INCREMENTS.ammo
			weapon.ammo_level += 1
		"range":
			weapon.range += UPGRADE_INCREMENTS.range
			weapon.range_level += 1
	
	coins_changed.emit()  # Changed signal
	weapon_upgraded.emit()
	
	print("Upgraded ", stat_name, " to level ", get_upgrade_level(stat_name))
	
	save_progress()
	return true


func get_upgrade_cost(stat_name: String) -> int:
	var level = get_upgrade_level(stat_name)
	var base_cost = UPGRADE_COSTS[stat_name]
	return int(base_cost * (1.0 + level * 0.5))


func get_upgrade_level(stat_name: String) -> int:
	var weapon = get_current_weapon()
	match stat_name:
		"damage": return weapon.get("damage_level", 0)
		"fire_rate": return weapon.get("fire_rate_level", 0)
		"ammo": return weapon.get("ammo_level", 0)
		"range": return weapon.get("range_level", 0)
	return 0


func get_stat_value(stat_name: String):
	var weapon = get_current_weapon()
	match stat_name:
		"damage": return weapon.get("damage", 0)
		"fire_rate": return weapon.get("fire_rate", 0.0)
		"ammo": return weapon.get("mag_size", 0)
		"range": return weapon.get("range", 0.0)
	return 0


# ============================================
# WEAPON PURCHASE
# ============================================

func can_afford_weapon(weapon_index: int) -> bool:
	if weapon_index < 0 or weapon_index >= shop_weapons.size():
		return false
	
	var weapon = shop_weapons[weapon_index]
	return coins >= weapon.cost and not weapon.owned  # Changed from gold


func buy_weapon(weapon_index: int) -> bool:
	if not can_afford_weapon(weapon_index):
		return false
	
	var shop_weapon = shop_weapons[weapon_index]
	coins -= shop_weapon.cost  # Changed from gold
	shop_weapon.owned = true
	
	var new_weapon = {
		"name": shop_weapon.name,
		"damage": shop_weapon.damage,
		"fire_rate": shop_weapon.fire_rate,
		"mag_size": shop_weapon.mag_size,
		"range": shop_weapon.range,
		"damage_level": 0,
		"fire_rate_level": 0,
		"ammo_level": 0,
		"range_level": 0
	}
	owned_weapons.append(new_weapon)
	
	active_weapon_index = owned_weapons.size() - 1
	
	coins_changed.emit()  # Changed signal
	weapon_purchased.emit()
	weapon_switched.emit()
	
	print("Purchased and equipped: ", shop_weapon.name)
	
	save_progress()
	return true


# ============================================
# APPLY TO GUN
# ============================================

func apply_to_gun(gun: Node):
	if gun == null:
		return
	
	var weapon = get_current_weapon()
	
	gun.damage = weapon.damage
	gun.fire_rate = weapon.fire_rate
	gun.mag_size = weapon.mag_size
	gun.current_ammo = weapon.mag_size
	
	print("Applied base weapon stats to gun: ", weapon.name)
	
	var player = null
	var current_node = gun.get_parent()
	
	for i in range(10):
		if current_node == null:
			break
		
		if current_node.is_in_group("player"):
			player = current_node
			break
		
		current_node = current_node.get_parent()
	
	if player == null:
		print("Warning: Could not find player node")
		return
	
	if "shoot_range" in player:
		player.shoot_range = weapon.range
		print("Updated player shoot_range to: ", weapon.range)
		
		var shoot_area = player.get_node_or_null("ShootRange")
		if shoot_area and shoot_area is Area3D:
			var collision = shoot_area.get_node_or_null("CollisionShape3D")
			if collision and collision.shape is SphereShape3D:
				collision.shape.radius = weapon.range
				print("Updated ShootRange radius to: ", weapon.range)
		
		var range_indicator = player.get_node_or_null("RangeIndicator")
		if range_indicator and range_indicator is MeshInstance3D:
			var mesh = range_indicator.mesh
			if mesh is TorusMesh:
				mesh.inner_radius = weapon.range - 0.1
				mesh.outer_radius = weapon.range + 0.1
				print("Updated RangeIndicator size")
	
	print("✅ Full weapon stats applied: ", weapon.name)


# ============================================
# COINS MANAGEMENT (Changed from Gold)
# ============================================

func add_coins(amount: int):
	coins += amount
	total_coins_collected += amount
	coins_changed.emit()
	print("🪙 Added ", amount, " coins. Total: ", coins)
	save_progress()


func get_coins() -> int:
	return coins
