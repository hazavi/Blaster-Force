# Blaster Force

Blaster Force is a 3D top-down shooter where you battle waves of enemies, collect coins, and upgrade your weapons. Fight through levels, defeat all enemies, and progress through increasingly challenging stages.

## Features

- Top-down 3D gameplay with smooth camera controls
- Multiple weapon types with distinct stats
- Weapon upgrade system (damage, fire rate, ammo, range)
- Coin collection and persistent progression
- Enemy AI with navigation and combat
- Health and ammo management
- Save/load system for progress persistence
- Shop system for purchasing and upgrading weapons

## Weapons

- **Blaster-C**: Balanced starter weapon
- **Blaster-G**: High fire rate, extended magazine
- **Blaster-Q**: High damage, close range

## Controls

- **WASD**: Move
- **Mouse**: Aim (automatic)
- **Auto-shoot**: Fires automatically when enemies are in range
- **R**: Reload
- **ESC**: Pause menu

## Gameplay

1. Eliminate all enemies in each level
2. Collect coins dropped by defeated enemies
3. Purchase and upgrade weapons in the shop
4. Complete levels to progress
5. Upgrade all weapon stats simultaneously for incremental improvements

## Game Managers (Autoloads)

- **GameManager**: Level progression and enemy tracking
- **WeaponUpgradeManager**: Weapon stats and upgrades
- **SaveManager**: Persistent data storage
- **PauseHandler**: Global pause system

## Technical Details

- **Engine**: Godot 4.x
- **Language**: GDScript (99.8%), GDShader (0.2%)
- **Architecture**: Autoload singleton pattern for managers
- **Save System**: JSON-based persistent storage

