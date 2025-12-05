class_name Barrel
extends CharacterBody2D

@onready var _entity_component: EntityComponent = %EntityComponent

func _ready() -> void:
	if not _entity_component:
		push_warning("EntityComponent not found on Barrel")

func _physics_process(delta: float) -> void:
	if not _entity_component:
		return
	
	velocity = _entity_component.compute_velocity(global_position, false, delta)
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) * 0.3

