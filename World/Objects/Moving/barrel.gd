class_name Barrel
extends CharacterBody2D

var _forces: Array[Force] = []
var _debug_forces_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var forces_velocity = Vector2.ZERO
	
	# Собираем все силы
	for i in range(_forces.size() - 1, -1, -1):
		var force: Force = _forces[i]
		var contribution: Vector2 = force.advance(delta)
		forces_velocity += contribution
		
		if force.is_finished():
			_forces.remove_at(i)
	
	# Применяем напрямую к velocity (как у игрока)
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
