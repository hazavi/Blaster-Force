extends CanvasLayer

# UI References
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/HealthLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/CoinsLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/WeaponLabel

# Player and gun references
var player: Node = null
var gun: Node = null
var upgrade_manager: Node = null

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	find_player()
	
	# Get upgrade manager
	upgrade_manager = get_node_or_null("/root/WeaponUpgradeManager")
	if upgrade_manager:
		upgrade_manager.weapon_switched.connect(_on_weapon_switched)
		# ✅ NEW: Also listen for weapon upgrades
		upgrade_manager.weapon_upgraded.connect(_on_weapon_switched)


func find_player():
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("HUD: Found player!")
		# ✅ NEW: Find gun dynamically (it changes based on weapon)
		update_gun_reference()
	else:
		print("HUD: Player not found!")


# ✅ NEW: Update gun reference
func update_gun_reference():
	if not player:
		return
	
	# Try to get the active gun from player
	if "gun" in player and player.gun != null:
		gun = player.gun
		print("HUD: Found gun at: ", gun.get_path())
	else:
		print("HUD: Gun not found!")


func _process(_delta):
	if player == null or not is_instance_valid(player):
		find_player()
		return
	
	# ✅ FIX: Update gun reference if it's null or invalid
	if gun == null or not is_instance_valid(gun):
		update_gun_reference()
	
	update_health()
	update_ammo()
	update_coins()
	update_weapon()


func _on_weapon_switched():
	update_weapon()
	# ✅ NEW: Update gun reference when weapon switches
	update_gun_reference()



func update_health():
	if player == null:
		return
	
	var current = player.health
	var maximum = player.max_health
	
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	
	if health_label:
		health_label.text = "HP: %d / %d" % [current, maximum]


func update_ammo():
	if player == null:
		return
	
	if gun == null:
		if ammo_label:
			ammo_label.text = "Ammo: -- / --"
		return
	
	if ammo_label:
		var current = gun.current_ammo
		var max_ammo = gun.mag_size
		
		if gun.is_reloading:
			ammo_label.text = "RELOADING..."
		else:
			ammo_label.text = "Ammo: %d / %d" % [current, max_ammo]


func update_coins():
	if player == null:
		return
	
	if coins_label:
		coins_label.text = "Coins: %d" % player.coins


func update_weapon():
	if weapon_label == null or upgrade_manager == null:
		return
	
	var weapon = upgrade_manager.get_current_weapon()
	weapon_label.text = "🔫 %s" % weapon.name
