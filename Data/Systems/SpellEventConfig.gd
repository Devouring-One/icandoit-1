class_name SpellEventConfig
extends Resource

@export var apply_damage: bool = false
@export var damage_amount: float = 0.0
@export var apply_force: bool = false
@export var force_magnitude: float = 200.0
@export var force_duration: float = 0.5
@export var nested_spells: Array[Spell] = []  # Array of Spells
