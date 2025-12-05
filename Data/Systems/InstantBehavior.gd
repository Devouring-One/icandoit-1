class_name InstantBehavior
extends SpellBehavior

func cast(spell, caster: Node2D, target_position: Vector2, original_caster: Node2D = null) -> void:
	var real_original_caster: Node2D = original_caster if original_caster else caster
	spell._trigger_event(spell.on_hit, caster, target_position, null, real_original_caster)
