class_name Force
extends Resource

@export var _vector: Vector2 = Vector2.ZERO
@export var _magnitude: float = 0.0
@export var _duration: float = 0.0
@export var _curve : Curve = _make_default_curve()
var _elapsed_time: float = 0.0

func _init(vector: Vector2 = Vector2.ZERO, magnitude: float = 0.0, duration: float = 0.0, curve: Curve = _make_default_curve()) -> void:
	_vector = vector
	_magnitude = magnitude
	_duration = duration
	_curve = curve
	_elapsed_time = 0.0

func get_force_strength(time: float) -> Vector2:
	if _duration <= 0.0:
		return Vector2.ZERO

	var normalized_time: float = clamp(time / _duration, 0.0, 1.0)
	var curve_value: float = _curve.sample_baked(normalized_time)
	return _vector * _magnitude * curve_value

func advance(delta: float) -> Vector2:
	_elapsed_time += delta
	return get_force_strength(_elapsed_time)

func reset_elapsed_time() -> void:
	_elapsed_time = 0.0

func is_finished() -> bool:
	return _duration > 0.0 and _elapsed_time >= _duration

static func _make_default_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(
		Vector2(0.0, 1.0),
		0.0, -1.0,
		Curve.TANGENT_LINEAR,
		Curve.TANGENT_FREE
	)
	curve.add_point(
		Vector2(1.0, 0.0),
		0.0, 0.0,
		Curve.TANGENT_FREE,
		Curve.TANGENT_LINEAR
	)
	curve.bake()
	return curve
