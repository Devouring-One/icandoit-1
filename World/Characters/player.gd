class_name Player
extends CharacterBody2D

@export var SPEED = 200
@export var _forces: Array[Force] = []

var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _draw_node: Control = null

var _debug_target_velocity: Vector2 = Vector2.ZERO
var _debug_forces_velocity: Vector2 = Vector2.ZERO
var _debug_final_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_draw_node = %DebugDrawLayer
	if not _draw_node:
		push_warning("DebugDrawLayer not found in scene")
		return
	
	_draw_node.draw.connect(_draw_target_marker)

func _clear_forces():
	_forces.clear()

func add_force(force: Force) -> void:
	if not force._vector == Vector2.ZERO:
		_forces.append(force)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var explosion_scene = preload("res://World/Effects/explosion.tscn")
			var explosion = explosion_scene.instantiate()
			explosion.global_position = get_global_mouse_position()
			get_parent().add_child(explosion)
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_target_position = get_global_mouse_position()
			_has_target = true
			if _draw_node:
				_draw_node.queue_redraw()

func _draw_target_marker() -> void:
	if not _has_target or not _draw_node:
		return
	
	var size = 10.0
	var color = Color.GREEN
	var thickness = 2.0
	
	_draw_node.draw_line(_target_position + Vector2(-size, 0), _target_position + Vector2(size, 0), color, thickness)
	_draw_node.draw_line(_target_position + Vector2(0, -size), _target_position + Vector2(0, size), color, thickness)

func _get_forces_for_debug() -> Dictionary:
	return {
		"forces": _forces,
		"target_velocity": _debug_target_velocity,
		"forces_velocity": _debug_forces_velocity,
		"velocity": _debug_final_velocity
	}

func _physics_process(delta: float) -> void:
	var target_velocity = Vector2.ZERO
	var forces_velocity = Vector2.ZERO
	
	for i in range(_forces.size() - 1, -1, -1):
		var force: Force = _forces[i]
		var contribution: Vector2 = force.advance(delta)
		forces_velocity += contribution
		
		if force.is_finished():
			_forces.remove_at(i)
	
	var forces_magnitude = forces_velocity.length()
	var target_weight = 1.0
	if forces_magnitude > 0:
		target_weight = clamp(1.0 - (forces_magnitude / SPEED), 0.3, 1.0)
	
	if _has_target:
		var to_target = _target_position - global_position
		var distance = to_target.length()
		
		if distance <= 2.0:
			global_position = _target_position
			_has_target = false
			if _draw_node:
				_draw_node.queue_redraw()
		else:
			var speed_this_frame = min(SPEED, distance / delta)
			target_velocity = to_target.normalized() * speed_this_frame * target_weight
	
	velocity = target_velocity + forces_velocity
	
	_debug_target_velocity = target_velocity
	_debug_forces_velocity = forces_velocity
	_debug_final_velocity = velocity
	
	move_and_slide()
