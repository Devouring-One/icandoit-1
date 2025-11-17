class_name Spell extends Resource

@export var name: String = "New Spell"
@export var mana_cost: float = 10.0
@export var spell_range: float = 300.0

enum SpellType {
	OFFENSIVE,
	DEFENSIVE,
	UTILITY
}

@export var type: SpellType = SpellType.OFFENSIVE
@export var cooldown: float = 1.0
@export var cast_time: float = 0.5
@export var description: String = "A powerful spell."
@export var spell_icon: Texture2D = null

## Modular behaviors that define what the spell does
@export var behaviors: Array[SpellBehavior] = []

## Cast the spell from caster towards target position
func cast(caster: Node2D, target_position: Vector2) -> void:
	for behavior in behaviors:
		if behavior == null:
			push_warning("Spell '%s' has null behavior in behaviors array" % name)
			continue
		var spawned: Node2D = behavior.on_cast(caster, target_position, self)
		if spawned and spawned.get_parent() == null:
			# Add to scene if behavior returned a node
			var world: Node = caster.get_tree().current_scene
			if world:
				world.add_child(spawned)