class_name ProjectileBehavior
extends "res://Data/Systems/SpellBehavior.gd"

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 300.0
@export var projectile_lifetime: float = 5.0
@export var pierce: bool = false

func on_cast(caster: Node2D, target_position: Vector2, spell: Spell) -> Node2D:
	if not projectile_scene:
		push_error("ProjectileBehavior: projectile_scene not set")
		return null
	
	var projectile: Projectile = projectile_scene.instantiate()
	if not projectile is Projectile:
		push_error("ProjectileBehavior: scene must be a Projectile")
		projectile.queue_free()
		return null
	
	projectile.speed = projectile_speed
	projectile.lifetime = projectile_lifetime
	projectile.pierce = pierce
	
	var direction: Vector2 = (target_position - caster.global_position).normalized()
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
	
	return projectile
