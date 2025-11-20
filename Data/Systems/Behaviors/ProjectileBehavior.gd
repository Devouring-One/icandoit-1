class_name ProjectileBehavior
extends SpellBehavior

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 300.0
@export var projectile_lifetime: float = 5.0
@export var pierce: bool = false

@export_group("Multi-shot")
@export var projectile_count: int = 1
@export_range(0, 180, 1, "radians_as_degrees") var spread_angle: float = 0.0

func on_cast(caster: Node2D, target_position: Vector2, spell: Spell) -> Node2D:
	if not projectile_scene:
		push_error("ProjectileBehavior: projectile_scene not set")
		return null
	
	var base_direction: Vector2 = (target_position - caster.global_position).normalized()
	var last_projectile: Node2D = null
	var world: Node = caster.get_tree().current_scene
	
	if not world:
		push_error("ProjectileBehavior: could not find current scene")
		return null
	
	# Calculate angle offsets for spread
	for i in range(projectile_count):
		var projectile: Projectile = projectile_scene.instantiate()
		if not projectile is Projectile:
			push_error("ProjectileBehavior: scene must be a Projectile")
			projectile.queue_free()
			continue
		
		projectile.speed = projectile_speed
		projectile.lifetime = projectile_lifetime
		projectile.pierce = pierce
		
		# Calculate direction with spread
		var angle_offset: float = 0.0
		if projectile_count > 1:
			# Distribute evenly across spread_angle
			var step: float = spread_angle / float(projectile_count - 1)
			angle_offset = -spread_angle / 2.0 + step * float(i)
		
		var direction: Vector2 = base_direction.rotated(angle_offset)
		projectile.setup(caster.global_position, direction, caster, spell)
		
		# Connect behaviors to projectile signals
		projectile.impacted.connect(func(body: Node2D):
			for behavior in spell.behaviors:
				behavior.on_impact(projectile, body, spell)
		)
		projectile.expired.connect(func():
			for behavior in spell.behaviors:
				behavior.on_expire(projectile, spell)
		)
		
		# Add to scene immediately
		world.add_child(projectile)
		last_projectile = projectile
	
	return last_projectile
