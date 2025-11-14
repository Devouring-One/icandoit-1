class_name Barrel
extends CharacterBody2D

@export var mass: float = 4.0
var _forces: Array[Force] = []
var _debug_forces_velocity: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	var forces_velocity = Vector2.ZERO
	
	for i in range(_forces.size() - 1, -1, -1):
		var force: Force = _forces[i]
		forces_velocity += force.get_current_force() / mass
		
		if force.is_finished():
			_forces.remove_at(i)
	
	velocity = forces_velocity
	_debug_forces_velocity = forces_velocity
	move_and_slide()

func add_force(force: Force) -> void:
	if not force._vector == Vector2.ZERO:
		_forces.append(force)

func _get_forces_for_debug() -> Dictionary:
	return {
		"forces": _forces,
		"forces_velocity": _debug_forces_velocity,
		"velocity": velocity
	}
