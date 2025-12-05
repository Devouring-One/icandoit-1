class_name Spell extends Resource

@export var name: String = "New Spell"
@export var cooldown: float = 0.0
@export var cast_time: float = 0.0
@export var description: String = "A powerful spell."
@export var spell_icon: Texture2D = null
@export var can_affect_caster: bool = false

@export var behavior: SpellBehavior

@export_group("Events")
@export var on_hit: SpellEventConfig
@export var on_bounce: SpellEventConfig
@export var on_expire: SpellEventConfig
@export var on_tick: SpellEventConfig
@export var tick_interval: float = 0.5

func cast(caster: Node2D, target_position: Vector2, original_caster_override: Node2D = null) -> void:
	if not behavior:
		push_error("Spell '%s': No behavior assigned" % name)
		return
	
	var real_original_caster: Node2D = original_caster_override if original_caster_override else caster
	(behavior as SpellBehavior).cast(self, caster, target_position, real_original_caster)

func _trigger_event(event_config: SpellEventConfig, source: Node2D, position: Vector2, target: Node2D, original_caster: Node2D = null) -> void:
	if not event_config:
		return
	
	if target and original_caster and target == original_caster and not can_affect_caster:
		return
	
	if event_config.apply_damage and target:
		var component := EntityComponent.get_from(target)
		if component:
			component.apply_damage(event_config.damage_amount)
	
	if event_config.apply_force and target:
		var direction: Vector2 = (target.global_position - position).normalized()
		if direction.length_squared() < 0.01:
			if source.has_method("get") and source.get("direction") != null:
				direction = source.direction
			else:
				direction = Vector2.RIGHT
		
		var force := Force.new(
			direction,
			event_config.force_magnitude,
			event_config.force_duration,
			target,
			0.0,
			Tween.TRANS_SINE,
			Tween.EASE_OUT
		)
		
		var component := EntityComponent.get_from(target)
		if component:
			component.add_force(force)
		else:
			for child in target.get_children():
				if child is ForceReceiver:
					child.add_force(force)
					break
	
	if event_config.nested_spells and event_config.nested_spells.size() > 0:
		for nested_resource in event_config.nested_spells:
			var nested := nested_resource as Spell
			if not nested:
				continue
			
			var target_pos: Vector2 = position
			if source.has_method("get") and source.get("direction") != null:
				target_pos = position + source.direction * 100.0
			elif source is Node2D and position == source.global_position:
				target_pos = position + Vector2.RIGHT.rotated(source.rotation) * 100.0
			
			nested.cast(source, target_pos, original_caster)

