class_name ForceDebugVisualizer
extends Node2D

@export var scale_factor: float = 0.2
@export var show_individual_forces: bool = true
@export var show_sum_forces: bool = true
@export var show_velocity: bool = true

var _parent_with_forces: Node = null

func _ready() -> void:
	_parent_with_forces = get_parent()
	if not _parent_with_forces or not _parent_with_forces.has_method("_get_forces_for_debug"):
		push_warning("ForceDebugVisualizer: parent must implement _get_forces_for_debug()")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not _parent_with_forces:
		return
	
	var debug_data = _parent_with_forces._get_forces_for_debug()
	var thickness = 2.0
	
	if show_individual_forces and debug_data.has("forces"):
		for force in debug_data.forces:
			var force_vec = force.get_current_force()
			if force_vec != Vector2.ZERO:
				draw_line(Vector2.ZERO, force_vec * scale_factor, Color.YELLOW, thickness * 0.7)
	
	if show_sum_forces and debug_data.has("forces_velocity"):
		var forces_velocity = debug_data.forces_velocity
		if forces_velocity != Vector2.ZERO:
			draw_line(Vector2.ZERO, forces_velocity * scale_factor, Color.RED, thickness)
	
	if debug_data.has("target_velocity"):
		var target_velocity = debug_data.target_velocity
		if target_velocity != Vector2.ZERO:
			draw_line(Vector2.ZERO, target_velocity * scale_factor, Color.GREEN, thickness)
	
	if show_velocity and debug_data.has("velocity"):
		var velocity = debug_data.velocity
		if velocity != Vector2.ZERO:
			draw_line(Vector2.ZERO, velocity * scale_factor, Color.CYAN, thickness)
