class_name EntityComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal died

const DEFAULT_HEALTH_BAR := preload("res://World/Objects/Components/UI/health_bar_display.tscn")

@export_group("Identity")
@export var entity_name: String = "Unnamed Entity"
@export_multiline var entity_description: String = "No description available."
@export var entity_icon: Texture2D = null

@export_group("Stats")
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var movement_speed: float = 200.0
@export var mass: float = 1.0
@export var can_move: bool = true

@export_group("Health UI")
@export var spawn_health_bar: bool = true
@export var health_bar_offset: Vector2 = Vector2(0, -48)
@export var health_bar_scene: PackedScene = DEFAULT_HEALTH_BAR
@export var show_health_label: bool = true
@export var destroy_owner_on_death: bool = false

@export_group("Gameplay")
@export var abilities: Array[String] = []
@export var resistances: Dictionary = {}

var forces: Array[Force] = []
var _health_bar: HealthBarDisplay = null
var _owner_body: Node = null
var _last_forces_velocity: Vector2 = Vector2.ZERO
var _last_target_velocity: Vector2 = Vector2.ZERO
var _last_final_velocity: Vector2 = Vector2.ZERO
var _last_forces_frame: int = -1

func _ready() -> void:
	_owner_body = get_parent()
	health = clamp(health, 0.0, max_health)
	_ensure_health_bar()
	_update_health_bar()

func add_force(force: Force) -> void:
	if force == null:
		return
	if force._vector == Vector2.ZERO:
		return
	forces.append(force)

func clear_forces() -> void:
	forces.clear()

func get_forces_velocity() -> Vector2:
	_ensure_forces_updated()
	return _last_forces_velocity

func apply_forces_to(base_velocity: Vector2) -> Vector2:
	_ensure_forces_updated()
	_last_target_velocity = base_velocity
	_last_final_velocity = base_velocity + _last_forces_velocity
	return _last_final_velocity

func apply_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_health(health - amount)

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_health(health + amount)

func set_health_exact(value: float) -> void:
	_set_health(value)

func _set_health(value: float) -> void:
	var new_value = clamp(value, 0.0, max_health)
	if is_equal_approx(new_value, health):
		return
	health = new_value
	_update_health_bar()
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()
		if destroy_owner_on_death and is_instance_valid(_owner_body):
			_owner_body.queue_free()

func set_max_health(value: float) -> void:
	max_health = max(value, 0.001)
	health = clamp(health, 0.0, max_health)
	_update_health_bar()

func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func get_mass() -> float:
	return max(mass, 0.001)

func get_forces() -> Array:
	return forces

func get_debug_snapshot() -> Dictionary:
	return {
		"forces": forces,
		"target_velocity": _last_target_velocity,
		"forces_velocity": _last_forces_velocity,
		"velocity": _last_final_velocity
	}

func _ensure_health_bar() -> void:
	if not spawn_health_bar:
		return
	if not is_instance_valid(_owner_body):
		return
	_health_bar = _owner_body.get_node_or_null("HealthBarDisplay")
	if not is_instance_valid(_health_bar) and health_bar_scene:
		_health_bar = health_bar_scene.instantiate()
		_health_bar.name = "HealthBarDisplay"
		_owner_body.add_child(_health_bar)
	if is_instance_valid(_health_bar):
		_health_bar.position = health_bar_offset
		_health_bar.show_label = show_health_label

func _update_health_bar() -> void:
	if is_instance_valid(_health_bar):
		_health_bar.set_health(health, max_health)

func _ensure_forces_updated() -> void:
	var frame := Engine.get_physics_frames()
	if _last_forces_frame == frame:
		return
	var accumulated := Vector2.ZERO
	for i in range(forces.size() - 1, -1, -1):
		var force: Force = forces[i]
		accumulated += force.get_current_force()
		if force.is_finished():
			forces.remove_at(i)
	if mass > 0.0:
		accumulated /= mass
	_last_forces_velocity = accumulated
	_last_forces_frame = frame

