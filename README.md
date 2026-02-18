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

| Weapon | Description | Strengths |
|--------|-------------|-----------|
| **Blaster-C** | Balanced starter weapon | Good all-around stats |
| **Blaster-G** | Assault rifle | High fire rate, extended magazine |
| **Blaster-Q** | Shotgun/heavy weapon | Massive damage, close range |

## Controls

| Input | Action |
|-------|--------|
| **WASD** | Move |
| **Mouse** | Aim (automatic) |
| **Auto-shoot** | Fires automatically when enemies in range |
| **R** | Reload |
| **ESC** | Pause menu |


## Gameplay

1. **Eliminate all enemies** in each level
2. **Collect coins** dropped by defeated enemies
3. **Visit the shop** to purchase new weapons
4. **Upgrade weapons** to increase damage, fire rate, ammo, and range
5. **Complete levels** to unlock new stages
6. **Survive and progress** through increasingly difficult challenges

## Game Managers (Autoloads)

| Manager | Purpose |
|---------|---------|
| **GameManager** | Level progression, enemy tracking, game state |
| **WeaponUpgradeManager** | Weapon stats, upgrades, weapon switching |
| **SaveManager** | Persistent data storage (JSON-based) |
| **LevelProgressManager** | Level unlocking and completion tracking |
| **PauseHandler** | Global pause system |
| **GunManager** | Gun model paths and base stats |

## Game Systems

### **Weapon System**
- Each weapon has base stats (damage, fire rate, mag size, reload time)
- Weapons can be upgraded incrementally (all 4 stats at once)
- Weapons are switched by showing/hiding models in GunPivot

### **Enemy AI**
- Enemies use range indicator to detect player.
- Different enemy types with unique behaviors
- Health bars displayed above enemies

### **Save System**
- Saves coins, owned weapons, active weapon, level progress
- Auto-saves when coins are collected, weapons purchased, or levels completed


## Technical Details

- **Engine**: Godot 4.x
- **Language**: GDScript (99.8%), GDShader (0.2%)
- **Architecture**: Autoload singleton pattern for managers
- **Save System**: JSON-based persistent storage

