class_name ForceReceiver
extends Node

## Lightweight component for objects that can receive forces but don't need full entity features

var forces: Array[Force] = []
var mass: float = 2.0

func add_force(force: Force) -> void:
	if force == null or force._vector == Vector2.ZERO:
		return
	forces.append(force)

func get_forces_velocity() -> Vector2:
	var accumulated := Vector2.ZERO
	for i in range(forces.size() - 1, -1, -1):
		var force: Force = forces[i]
		accumulated += force.get_current_force()
		if force.is_finished():
			forces.remove_at(i)
	if mass > 0.0:
		accumulated /= mass
	return accumulated

func clear_forces() -> void:
	forces.clear()
