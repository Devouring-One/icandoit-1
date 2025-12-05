class_name ProjectileConfig
extends SpellBehavior

@export var projectile_scene: PackedScene = preload("res://World/Spells/Projectile.tscn")
@export var speed: float = 300.0
@export var lifetime: float = 2.0
@export var pierce: bool = false
@export var can_affect_caster: bool = false
@export var affected_by_forces: bool = true
@export var force_influence: float = 0.3

@export_group("Speed Animation")
@export var animate_speed: bool = false
@export var target_speed: float = 600.0
@export var speed_transition_duration: float = 0
@export var speed_trans_type: Tween.TransitionType = Tween.TRANS_LINEAR
@export var speed_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

@export_group("Bounce")
@export var can_bounce: bool = false
@export var max_bounces: int = 3
@export var bounce_from_bodies: bool = true
@export var bounce_from_projectiles: bool = false
@export var bounce_speed_multiplier: float = 1.0

@export_group("Multi-shot")
@export var projectile_count: int = 1
@export var omnidirectional: bool = false
@export_range(0, 180, 1, "radians_as_degrees") var spread_angle: float = 0.0
@export var instant_cast: bool = true
@export var cast_duration: float = 1.0
@export var clockwise: bool = true

func cast(spell, caster: Node2D, target_position: Vector2, original_caster: Node2D = null) -> void:
	if not projectile_scene:
		push_error("ProjectileConfig: projectile_scene is not set")
		return
	
	var real_original_caster: Node2D = original_caster if original_caster else caster
	
	var base_direction: Vector2 = (target_position - caster.global_position).normalized()
	
	if base_direction.length_squared() < 0.01:
		base_direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	var world: Node = caster.get_tree().current_scene
	
	if instant_cast:
		for i in range(projectile_count):
			_spawn_projectile(i, spell, caster, base_direction, world, real_original_caster)
	else:
		var delay_between: float = cast_duration / float(projectile_count) if projectile_count > 1 else 0.0
		for i in range(projectile_count):
			var delay: float = delay_between
			if delay > 0.0:
				await caster.get_tree().create_timer(delay).timeout
			_spawn_projectile(i, spell, caster, base_direction, world, real_original_caster)

func _spawn_projectile(index: int, spell, caster: Node2D, base_direction: Vector2, world: Node, original_caster: Node2D) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	
	projectile.speed = speed
	projectile.lifetime = lifetime
	projectile.pierce = pierce
	projectile.can_affect_caster = spell.can_affect_caster and can_affect_caster
	projectile.affected_by_forces = affected_by_forces
	projectile.force_influence = force_influence
	
	projectile.can_bounce = can_bounce
	projectile.max_bounces = max_bounces
	projectile.bounce_from_bodies = bounce_from_bodies
	projectile.bounce_from_projectiles = bounce_from_projectiles
	projectile.bounce_speed_multiplier = bounce_speed_multiplier
	
	projectile.animate_speed = animate_speed
	projectile.target_speed = target_speed
	projectile.speed_transition_duration = speed_transition_duration
	projectile.speed_trans_type = speed_trans_type
	projectile.speed_ease_type = speed_ease_type
	
	var angle_offset: float = 0.0
	if omnidirectional:
		var angle_step: float = TAU / float(projectile_count)
		angle_offset = angle_step * float(index)
		if not clockwise:
			angle_offset = -angle_offset
	elif projectile_count > 1:
		var step: float = spread_angle / float(projectile_count - 1)
		angle_offset = -spread_angle / 2.0 + step * float(index)
	
	var direction: Vector2 = base_direction.rotated(angle_offset)
	projectile.setup(caster.global_position, direction, caster, spell, original_caster)
	
	var spell_ref = spell
	var original_caster_ref = original_caster
	
	projectile.impacted.connect(func(body: Node2D):
		if is_instance_valid(projectile):
			var safe_original = original_caster_ref if is_instance_valid(original_caster_ref) else null
			spell_ref._trigger_event(spell_ref.on_hit, projectile, projectile.global_position, body, safe_original)
	)
	projectile.bounced.connect(func(body: Node2D):
		if is_instance_valid(projectile):
			var safe_original = original_caster_ref if is_instance_valid(original_caster_ref) else null
			spell_ref._trigger_event(spell_ref.on_bounce, projectile, projectile.global_position, body, safe_original)
	)
	projectile.expired.connect(func():
		if is_instance_valid(projectile):
			var safe_original = original_caster_ref if is_instance_valid(original_caster_ref) else null
			spell_ref._trigger_event(spell_ref.on_expire, projectile, projectile.global_position, null, safe_original)
	)
	
	world.add_child(projectile)
	
	if spell.on_tick and spell.tick_interval > 0.0:
		var tick_timer := Timer.new()
		tick_timer.wait_time = spell.tick_interval
		tick_timer.one_shot = false
		tick_timer.timeout.connect(func():
			if is_instance_valid(projectile):
				spell._trigger_event(spell.on_tick, projectile, projectile.global_position, null, caster)
		)
		projectile.add_child(tick_timer)
		tick_timer.start()
