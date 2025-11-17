class_name SpellBehavior
extends Resource

## Base class for modular spell behaviors.
## Subclasses override methods to add specific functionality.

## Called when spell is cast. Returns optional scene to spawn (e.g., projectile).
func on_cast(_caster: Node2D, _target_position: Vector2, _spell: Spell) -> Node2D:
	return null

## Called when projectile/spell hits something.
func on_impact(_projectile: Node2D, _hit_body: Node2D, _spell: Spell) -> void:
	pass

## Called when projectile/spell expires without hitting.
func on_expire(_projectile: Node2D, _spell: Spell) -> void:
	pass
