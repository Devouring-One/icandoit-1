class_name SpawnExplosionBehavior
extends "res://Data/Systems/SpellBehavior.gd"

@export var explosion_scene: PackedScene
@export var explosion_radius: float = 100.0
@export var explosion_force: float = 300.0
@export var explosion_damage: float = 5.0

func on_impact(projectile: Node2D, _hit_body: Node2D, _spell: Spell) -> void:
	if projectile:
		_spawn_explosion(projectile.global_position)

func on_expire(projectile: Node2D, _spell: Spell) -> void:
	if projectile:
		_spawn_explosion(projectile.global_position)

func _spawn_explosion(at_position: Vector2) -> void:
	if not explosion_scene:
		push_warning("SpawnExplosionBehavior: explosion_scene not set")
		return
	
	var explosion: Node2D = explosion_scene.instantiate()
	
	# Get current scene first
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		push_error("SpawnExplosionBehavior: Could not get SceneTree")
		explosion.queue_free()
		return
	
	var world: Node = scene_tree.current_scene
	if not world:
		push_error("SpawnExplosionBehavior: No current scene")
		explosion.queue_free()
		return
	
	# Set position before adding to tree
	explosion.global_position = at_position
	
	# Configure before adding to tree
	if explosion.has_method("setup"):
		explosion.setup(explosion_radius, explosion_force, explosion_damage)
	
	# Defer adding to scene to avoid "flushing queries" error
	world.call_deferred("add_child", explosion)
