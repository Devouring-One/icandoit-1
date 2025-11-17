class_name Force
extends RefCounted

@export var _vector: Vector2 = Vector2.ZERO
@export var _magnitude: float = 0.0
@export var _duration: float = 0.0
@export var _current_strength: float = 1.0
@export var _is_finished: bool = false
var _tween: Tween = null
var _node: Node = null
@export var _trans_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var _ease_type: Tween.EaseType = Tween.EASE_OUT

func _init(vector: Vector2, magnitude: float, base_duration: float, node: Node, duration_coefficient: float = 0.0, trans_type: Tween.TransitionType = Tween.TRANS_CUBIC, ease_type: Tween.EaseType = Tween.EASE_OUT) -> void:
	_vector = vector.normalized()
	_magnitude = magnitude
	_duration = base_duration + (magnitude * duration_coefficient)
	_node = node
	_trans_type = trans_type
	_ease_type = ease_type
	
	_tween = node.create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, "_current_strength", 0.0, _duration).set_trans(_trans_type).set_ease(_ease_type)
	_tween.finished.connect(_on_tween_finished)

func get_current_force() -> Vector2:
	if _is_finished:
		return Vector2.ZERO
	return _vector * _magnitude * _current_strength

func is_finished() -> bool:
	return _is_finished

func _on_tween_finished() -> void:
	_is_finished = true
