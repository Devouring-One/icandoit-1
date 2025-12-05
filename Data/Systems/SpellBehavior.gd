class_name SpellBehavior
extends Resource

@warning_ignore("unused_parameter")
func cast(spell, caster: Node2D, target_position: Vector2, original_caster: Node2D = null) -> void:
	push_error("SpellBehavior.cast() must be overridden in subclass")
