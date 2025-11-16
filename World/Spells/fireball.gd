class_name Fireball
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0
@export var max_distance: float = 600.0
@export var auto_explode_on_area: bool = true

var _direction: Vector2 = Vector2.ZERO
var _distance_traveled: float = 0.0
var _owner: Node = null
var _exploded: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if auto_explode_on_area:
		area_entered.connect(_on_area_entered)

func launch(direction: Vector2, source: Node) -> void:
	_direction = direction.normalized()
	_owner = source
	_distance_traveled = 0.0

func _physics_process(delta: float) -> void:
	if _exploded or _direction == Vector2.ZERO:
		return

	var delta_move = _direction * speed * delta
	global_position += delta_move
	_distance_traveled += delta_move.length()

	if _distance_traveled >= max_distance:
		_explode()

func _on_body_entered(body: Node) -> void:
	if body == _owner:
		return
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
	_explode()

func _on_area_entered(area: Area2D) -> void:
	if area == _owner:
		return
	_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	call_deferred("_spawn_explosion")

func _spawn_explosion() -> void:
	var explosion = Explosion.new()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	queue_free()
