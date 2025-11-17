class_name RaycastBehavior
extends "res://Data/Systems/SpellBehavior.gd"

@export var max_range: float = 1000.0
@export var collision_mask: int = 1  ## Which layers to hit (enemies, walls, etc)

func on_cast(caster: Node2D, target_position: Vector2, spell: Spell) -> Node2D:
	var direction: Vector2 = (target_position - caster.global_position).normalized()
	var distance_to_target: float = caster.global_position.distance_to(target_position)
	var actual_range: float = min(distance_to_target, max_range)
	var ray_end: Vector2 = caster.global_position + direction * actual_range
	
	# Raycast from caster to target (or max_range)
	var space_state: PhysicsDirectSpaceState2D = caster.get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		caster.global_position,
		ray_end
	)
	query.exclude = [caster.get_rid()]
	query.collision_mask = collision_mask
	
	var result: Dictionary = space_state.intersect_ray(query)
	
	# Determine hit position
	var hit_position: Vector2
	var hit_body: Node2D = null
	
	if result:
		hit_position = result.position
		hit_body = result.collider as Node2D
	else:
		hit_position = ray_end
	
	# Create a temporary node at hit position for other behaviors
	var hit_marker: Node2D = Node2D.new()
	hit_marker.global_position = hit_position
	
	# Trigger other behaviors at hit position
	for behavior in spell.behaviors:
		if behavior != self:
			if hit_body:
				behavior.on_impact(hit_marker, hit_body, spell)
			else:
				behavior.on_expire(hit_marker, spell)
	
	return null  # No scene to spawn, raycast is instant
