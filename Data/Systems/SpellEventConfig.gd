class_name SpellEventConfig
extends Resource

@export var apply_damage: bool = false
@export var damage_amount: float = 0.0
@export var nested_spell: Resource  # Spell (avoiding circular dependency)
