class_name Spell extends Resource

enum CastType {
	PROJECTILE,
	RAYCAST,
	AREA,
	INSTANT,
	CHANNELING,
	BUFF
}

@export var name: String = "New Spell"
@export var cooldown: float = 0.5
@export var cast_time: float = 0.5
@export var description: String = "A powerful spell."
@export var spell_icon: Texture2D = null

@export_group("Cast Behavior")
@export var cast_type: CastType = CastType.INSTANT
@export var projectile_config: ProjectileConfig
@export var raycast_config: RaycastConfig
@export var area_radius: float = 100.0
@export var area_force: float = 400.0

@export_group("Nested Spells")
@export var on_hit: SpellEventConfig
@export var on_expire: SpellEventConfig
@export var on_tick: SpellEventConfig
@export var tick_interval: float = 0.5

func _validate_property(property: Dictionary) -> void:
	# Hide config fields based on cast_type
	match cast_type:
		CastType.PROJECTILE:
			if property.name in ["raycast_config", "area_radius", "area_force"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		CastType.RAYCAST:
			if property.name in ["projectile_config", "area_radius", "area_force", "on_expire", "on_tick", "tick_interval"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		CastType.AREA:
			if property.name in ["projectile_config", "raycast_config", "on_expire", "on_tick", "tick_interval"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		CastType.INSTANT:
			if property.name in ["projectile_config", "raycast_config", "area_radius", "area_force", "on_expire", "on_tick", "tick_interval"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		CastType.CHANNELING, CastType.BUFF:
			if property.name in ["projectile_config", "raycast_config", "area_radius", "area_force", "on_hit", "on_expire", "on_tick", "tick_interval"]:
				property.usage = PROPERTY_USAGE_NO_EDITOR

## Cast the spell from caster towards target position
func cast(caster: Node2D, target_position: Vector2) -> void:
	match cast_type:
		CastType.PROJECTILE:
			_cast_projectile(caster, target_position)
		CastType.RAYCAST:
			_cast_raycast(caster, target_position)
		CastType.AREA:
			_cast_area(caster, target_position)
		CastType.INSTANT:
			_cast_instant(caster, target_position)
		CastType.CHANNELING:
			push_warning("CHANNELING cast type not implemented yet")
		CastType.BUFF:
			push_warning("BUFF cast type not implemented yet")

func _cast_projectile(caster: Node2D, target_position: Vector2) -> void:
	if not projectile_config:
		push_error("Spell '%s': PROJECTILE cast type requires projectile_config" % name)
		return
	
	var projectile_scene: PackedScene = preload("res://World/Spells/Projectile.tscn")
	var base_direction: Vector2 = (target_position - caster.global_position).normalized()
	var world: Node = caster.get_tree().current_scene
	
	for i in range(projectile_config.projectile_count):
		var projectile: Projectile = projectile_scene.instantiate()
		
		# Apply config
		projectile.speed = projectile_config.speed
		projectile.lifetime = projectile_config.lifetime
		projectile.pierce = projectile_config.pierce
		projectile.affected_by_forces = projectile_config.affected_by_forces
		projectile.force_influence = projectile_config.force_influence
		
		# Calculate spread
		var angle_offset: float = 0.0
		if projectile_config.projectile_count > 1:
			var step: float = projectile_config.spread_angle / float(projectile_config.projectile_count - 1)
			angle_offset = -projectile_config.spread_angle / 2.0 + step * float(i)
		
		var direction: Vector2 = base_direction.rotated(angle_offset)
		projectile.setup(caster.global_position, direction, caster, self)
		
		# Connect nested spell events
		projectile.impacted.connect(func(body: Node2D):
			_trigger_event(on_hit, projectile, projectile.global_position, body)
		)
		projectile.expired.connect(func():
			_trigger_event(on_expire, projectile, projectile.global_position, null)
		)
		
		# Setup tick spell
		if on_tick and tick_interval > 0.0:
			var tick_timer := Timer.new()
			tick_timer.wait_time = tick_interval
			tick_timer.timeout.connect(func():
				if is_instance_valid(projectile):
					_trigger_event(on_tick, projectile, projectile.global_position, null)
			)
			projectile.add_child(tick_timer)
			tick_timer.start()
		
		world.add_child(projectile)

func _cast_raycast(caster: Node2D, target_position: Vector2) -> void:
	if not raycast_config:
		push_error("Spell '%s': RAYCAST cast type requires raycast_config" % name)
		return
	
	var space_state := caster.get_world_2d().direct_space_state
	var direction: Vector2 = (target_position - caster.global_position).normalized()
	var distance: float = caster.global_position.distance_to(target_position)
	var ray_length: float = min(distance, raycast_config.max_range)
	
	var query := PhysicsRayQueryParameters2D.create(
		caster.global_position,
		caster.global_position + direction * ray_length
	)
	query.exclude = [caster.get_rid()]
	query.collision_mask = raycast_config.collision_mask
	
	var result := space_state.intersect_ray(query)
	
	if result:
		var hit_position: Vector2 = result.position
		var hit_body: Node2D = result.collider
		
		# Visual marker
		var marker := Node2D.new()
		marker.global_position = hit_position
		caster.get_tree().current_scene.add_child(marker)
		marker.queue_free()
		
		# Trigger event
		_trigger_event(on_hit, caster, hit_position, hit_body)
	else:
		# Ray didn't hit anything
		if on_expire:
			var end_pos: Vector2 = caster.global_position + direction * ray_length
			_trigger_event(on_expire, caster, end_pos, null)

func _cast_area(caster: Node2D, target_position: Vector2) -> void:
	var explosion: Explosion = Explosion.new()
	explosion.global_position = target_position
	explosion.collision_mask_bits = 5
	
	# Calculate damage from on_hit event config
	var damage: float = 0.0
	if on_hit and on_hit.apply_damage:
		damage = on_hit.damage_amount
	
	explosion.setup(area_radius, area_force, damage)
	caster.get_tree().current_scene.call_deferred("add_child", explosion)
	
	# Trigger nested spell if exists (but not damage - explosion handles that)
	if on_hit and on_hit.nested_spell:
		on_hit.nested_spell.cast(caster, target_position)

func _cast_instant(caster: Node2D, target_position: Vector2) -> void:
	_trigger_event(on_hit, caster, target_position, null)

func _trigger_event(event_config: SpellEventConfig, source: Node2D, position: Vector2, target: Node2D) -> void:
	if not event_config:
		return
	
	# Apply damage to target
	if event_config.apply_damage and target:
		var component := EntityComponent.get_from(target)
		if component:
			component.apply_damage(event_config.damage_amount)
	
	# Cast nested spell
	if event_config.nested_spell:
		# For nested spells, generate a target position ahead of source
		var target_pos: Vector2 = position
		if source.has_method("get") and source.get("direction") != null:
			# If source has direction (like Projectile), use it
			target_pos = position + source.direction * 100.0
		elif source is Node2D and position == source.global_position:
			# Otherwise use source rotation
			target_pos = position + Vector2.RIGHT.rotated(source.rotation) * 100.0
		event_config.nested_spell.cast(source, target_pos)