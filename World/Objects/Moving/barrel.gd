class_name Barrel
extends CharacterBody2D

@onready var _entity_component: EntityComponent = %EntityComponent

func _ready() -> void:
	if not _entity_component:
		push_warning("EntityComponent not found on Barrel")

func _physics_process(_delta: float) -> void:
	if not _entity_component:
		return
	velocity = _entity_component.apply_forces_to(Vector2.ZERO)
	move_and_slide()

func add_force(force: Force) -> void:
	if _entity_component:
		_entity_component.add_force(force)

func apply_damage(amount: float) -> void:
	if not _entity_component:
		return
	_entity_component.apply_damage(amount)
	if _entity_component.get_health() <= 0.0 and is_inside_tree():
		queue_free()

func _on_regen_timer_timeout() -> void:
	if _entity_component and _entity_component.get_health() > 0.0:
		_entity_component.heal(1.0)

func _get_forces_for_debug() -> Dictionary:
	if _entity_component:
		return _entity_component.get_debug_snapshot()
	return {}
