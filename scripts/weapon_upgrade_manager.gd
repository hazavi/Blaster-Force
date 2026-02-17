extends Node

# ============================================
# WEAPON UPGRADE MANAGER - Persistent system
# ============================================

# Currency
var gold: int = 500  # Starting gold

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
		"fire_rate": 0.15,  # Faster!
		"mag_size": 30,
		"range": 8.0,
		"owned": false
	},
	{
		"name": "Blaster-Q",
		"cost": 400,
		"damage": 35,
		"fire_rate": 0.8,  # Slower but powerful
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
	"damage": 5,
	"fire_rate": 0.05,  # Reduces cooldown
	"ammo": 6,
	"range": 1.5
}

signal gold_changed
signal weapon_upgraded
signal weapon_purchased
signal weapon_switched


func _ready():
	# Initialize with starter weapon
	owned_weapons.append({
		"name": "Blaster-C",
		"damage": 20,
		"fire_rate": 0.3,
		"mag_size": 12,
		"range": 6.0,
		"damage_level": 0,
		"fire_rate_level": 0,
		"ammo_level": 0,
		"range_level": 0
	})
	
	print("=== WEAPON UPGRADE MANAGER READY ===")
	print("Gold: ", gold)
	print("Starting Weapon: ", owned_weapons[0].name)


# ============================================
# WEAPON ACCESS
# ============================================

func get_current_weapon() -> Dictionary:
	"""Get currently equipped weapon"""
	if active_weapon_index >= 0 and active_weapon_index < owned_weapons.size():
		return owned_weapons[active_weapon_index]
	return owned_weapons[0]  # Fallback to first weapon


func get_owned_weapons() -> Array[Dictionary]:
	"""Get all owned weapons"""
	return owned_weapons


func switch_weapon(weapon_index: int):
	"""Switch to a different owned weapon"""
	if weapon_index >= 0 and weapon_index < owned_weapons.size():
		active_weapon_index = weapon_index
		weapon_switched.emit()
		print("Switched to: ", owned_weapons[weapon_index].name)
		return true
	return false


func get_active_weapon_index() -> int:
	return active_weapon_index


# ============================================
# UPGRADE FUNCTIONS
# ============================================

func can_afford_upgrade(stat_name: String) -> bool:
	var cost = get_upgrade_cost(stat_name)
	return gold >= cost


func upgrade_stat(stat_name: String) -> bool:
	if not can_afford_upgrade(stat_name):
		return false
	
	var cost = get_upgrade_cost(stat_name)
	gold -= cost
	
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
	
	gold_changed.emit()
	weapon_upgraded.emit()
	
	print("Upgraded ", stat_name, " to level ", get_upgrade_level(stat_name))
	return true


func get_upgrade_cost(stat_name: String) -> int:
	var level = get_upgrade_level(stat_name)
	var base_cost = UPGRADE_COSTS[stat_name]
	
	# Cost scales: base * (1 + level * 0.5)
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
	return gold >= weapon.cost and not weapon.owned


func buy_weapon(weapon_index: int) -> bool:
	if not can_afford_weapon(weapon_index):
		return false
	
	var shop_weapon = shop_weapons[weapon_index]
	gold -= shop_weapon.cost
	shop_weapon.owned = true
	
	# Add to owned weapons
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
	
	# Auto-equip new weapon
	active_weapon_index = owned_weapons.size() - 1
	
	gold_changed.emit()
	weapon_purchased.emit()
	weapon_switched.emit()
	
	print("Purchased and equipped: ", shop_weapon.name)
	return true


# ============================================
# APPLY TO GUN
# ============================================

func apply_to_gun(gun: Node):
	"""Apply current weapon stats to gun"""
	if gun == null:
		return
	
	var weapon = get_current_weapon()
	
	gun.damage = weapon.damage
	gun.fire_rate = weapon.fire_rate
	gun.mag_size = weapon.mag_size
	gun.current_ammo = weapon.mag_size
	
	print("Applied base weapon stats to gun: ", weapon.name)
	
	# Find player by traversing up the tree
	var player = null
	var current_node = gun.get_parent()
	
	# Traverse up to find the player (CharacterBody3D with "player" group)
	for i in range(10):  # Max 10 levels up
		if current_node == null:
			break
		
		if current_node.is_in_group("player"):
			player = current_node
			break
		
		current_node = current_node.get_parent()
	
	if player == null:
		print("Warning: Could not find player node")
		return
	
	# Update shoot range on player
	if "shoot_range" in player:
		player.shoot_range = weapon.range
		print("Updated player shoot_range to: ", weapon.range)
		
		# Update shoot range area collision shape
		var shoot_area = player.get_node_or_null("ShootRange")
		if shoot_area and shoot_area is Area3D:
			var collision = shoot_area.get_node_or_null("CollisionShape3D")
			if collision and collision.shape is SphereShape3D:
				collision.shape.radius = weapon.range
				print("Updated ShootRange radius to: ", weapon.range)
		
		# Update range indicator visual
		var range_indicator = player.get_node_or_null("RangeIndicator")
		if range_indicator and range_indicator is MeshInstance3D:
			var mesh = range_indicator.mesh
			if mesh is TorusMesh:
				mesh.inner_radius = weapon.range - 0.1
				mesh.outer_radius = weapon.range + 0.1
				print("Updated RangeIndicator size")
	
	print("✅ Full weapon stats applied: ", weapon.name)


# ============================================
# GOLD MANAGEMENT
# ============================================

func add_gold(amount: int):
	gold += amount
	gold_changed.emit()


func get_gold() -> int:
	return gold
