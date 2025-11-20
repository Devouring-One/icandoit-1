class_name CastSpellOnImpactBehavior
extends SpellBehavior

@export var spell_to_cast: Spell
@export var cast_on_expire: bool = false

func on_impact(source: Node2D, _body: Node2D, _spell: Spell) -> void:
	if not spell_to_cast:
		return
	
	# Cast the spell at impact location
	if source and is_instance_valid(source):
		spell_to_cast.cast(source, source.global_position)

func on_expire(source: Node2D, _spell: Spell) -> void:
	if not spell_to_cast or not cast_on_expire:
		return
	
	# Cast the spell at expiration location
	if source and is_instance_valid(source):
		spell_to_cast.cast(source, source.global_position)
