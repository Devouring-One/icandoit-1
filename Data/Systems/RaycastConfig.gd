class_name RaycastConfig
extends SpellBehavior

@export var max_range: float = 1000.0
@export var collision_mask: int = 1
@export var pierce: bool = false
@export var pierce_count: int = 0

func cast(spell, caster: Node2D, target_position: Vector2, original_caster: Node2D = null) -> void:
	var real_original_caster: Node2D = original_caster if original_caster else caster
	var space_state := caster.get_world_2d().direct_space_state
	var direction: Vector2 = (target_position - caster.global_position).normalized()
	
	if direction.length_squared() < 0.01:
		direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	var distance: float = caster.global_position.distance_to(target_position)
	var ray_length: float = min(distance, max_range) if distance > 0 else max_range
	
	var query := PhysicsRayQueryParameters2D.create(
		caster.global_position,
		caster.global_position + direction * ray_length
	)
	query.exclude = [caster.get_rid()]
	query.collision_mask = collision_mask
	
	var result := space_state.intersect_ray(query)
	
	if result:
		var hit_position: Vector2 = result.position
		var hit_body: Node2D = result.collider
		
		if hit_body == real_original_caster and not spell.can_affect_caster:
			if spell.on_expire:
				var end_pos: Vector2 = caster.global_position + direction * ray_length
				spell._trigger_event(spell.on_expire, caster, end_pos, null, real_original_caster)
			return
		
		var marker := Node2D.new()
		marker.global_position = hit_position
		caster.get_tree().current_scene.add_child(marker)
		marker.queue_free()
		
		spell._trigger_event(spell.on_hit, caster, hit_position, hit_body, real_original_caster)
	else:
		if spell.on_expire:
			var end_pos: Vector2 = caster.global_position + direction * ray_length
			spell._trigger_event(spell.on_expire, caster, end_pos, null, real_original_caster)
