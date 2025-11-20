class_name DamageOnImpactBehavior
extends SpellBehavior

@export var damage: float = 10.0

func on_impact(_projectile: Node2D, hit_body: Node2D, _spell: Spell) -> void:
	var entity_component: EntityComponent = EntityComponent.get_from(hit_body)
	if entity_component:
		entity_component.apply_damage(damage)
