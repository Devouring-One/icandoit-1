class_name EntityComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal died

@export_group("Identity")
@export var entity_name: String = "Unnamed Entity"

@export_group("Stats")
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var mass: float = 1.0
@export var movement_speed: float = 200.0

@export_group("Gameplay")
@export var destroy_owner_on_death: bool = false

@export_group("Regeneration")
@export var regen_enabled: bool = false
@export var regen_amount: float = 1.0
@export var regen_interval: float = 1.0

var forces: Array[Force] = []
var _regen_timer: Timer = null
var _owner_body: Node = null
var _last_forces_velocity: Vector2 = Vector2.ZERO
var _last_target_velocity: Vector2 = Vector2.ZERO
var _last_final_velocity: Vector2 = Vector2.ZERO
var _last_forces_frame: int = -1

static func get_from(node: Node) -> EntityComponent:
	if node == null:
		return null
	if node is EntityComponent:
		return node
	for child in node.get_children():
		if child is EntityComponent:
			return child
	return null

func _ready() -> void:
	_owner_body = get_parent()
	health = clamp(health, 0.0, max_health)
	
	if regen_enabled:
		_regen_timer = Timer.new()
		_regen_timer.wait_time = regen_interval
		_regen_timer.autostart = true
		_regen_timer.timeout.connect(_on_regen_timer_timeout)
		add_child(_regen_timer)

func add_force(force: Force) -> void:
	if force == null:
		return
	if force._vector == Vector2.ZERO:
		return
	forces.append(force)

func get_forces_velocity() -> Vector2:
	_ensure_forces_updated()
	return _last_forces_velocity

func apply_forces_to(base_velocity: Vector2) -> Vector2:
	_ensure_forces_updated()
	_last_target_velocity = base_velocity
	_last_final_velocity = base_velocity + _last_forces_velocity
	return _last_final_velocity

func compute_velocity(target_position: Vector2, has_target: bool, delta: float) -> Vector2:
	_ensure_forces_updated()
	
	var target_velocity := Vector2.ZERO
	var forces_magnitude := _last_forces_velocity.length()
	var target_weight := 1.0
	
	if forces_magnitude > 0:
		target_weight = clamp(1.0 - (forces_magnitude / movement_speed), 0.1, 1.0)
	
	if has_target and is_instance_valid(_owner_body):
		var to_target: Vector2 = target_position - _owner_body.global_position
		var distance: float = to_target.length()
		
		if distance > 2.0:
			var speed_this_frame: float = min(movement_speed, distance / delta)
			target_velocity = to_target.normalized() * speed_this_frame * target_weight
	
	_last_target_velocity = target_velocity
	_last_final_velocity = target_velocity + _last_forces_velocity
	return _last_final_velocity

func apply_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_health(health - amount)

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_health(health + amount)

func is_alive() -> bool:
	return health > 0.0

func _set_health(value: float) -> void:
	var new_value = clamp(value, 0.0, max_health)
	if is_equal_approx(new_value, health):
		return
	health = new_value
	health_changed.emit(health, max_health)
	if health <= 0.0:
		if _regen_timer:
			_regen_timer.stop()
		died.emit()
		if destroy_owner_on_death and is_instance_valid(_owner_body):
			_owner_body.queue_free()

func set_max_health(value: float) -> void:
	max_health = max(value, 0.001)
	health = clamp(health, 0.0, max_health)
	health_changed.emit(health, max_health)

func get_debug_snapshot() -> Dictionary:
	return {
		"forces": forces,
		"target_velocity": _last_target_velocity,
		"forces_velocity": _last_forces_velocity,
		"velocity": _last_final_velocity
	}

func _on_regen_timer_timeout() -> void:
	if not regen_enabled:
		return
	if regen_amount <= 0.0:
		return
	if health <= 0.0:
		return
	heal(regen_amount)

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

func apply_push(push_force: Vector2, pusher_mass: float = 1.0, push_duration: float = 0.3) -> void:
	var resistance := mass / (mass + pusher_mass)
	var adjusted_force := push_force * (1.0 - resistance)
	
	if adjusted_force.length_squared() < 1.0:
		return
	
	var force := Force.new(
		adjusted_force.normalized(),
		adjusted_force.length(),
		push_duration,
		_owner_body,
		0.0,
		Tween.TRANS_QUAD,
		Tween.EASE_OUT
	)
	
	add_force(force)

func calculate_push_to(other: Node2D, collision_normal: Vector2, my_velocity: Vector2) -> Dictionary:
	var other_component := EntityComponent.get_from(other)
	if not other_component:
		return {"can_push": false}
	
	var other_mass := other_component.mass
	var total_mass := mass + other_mass
	
	var my_momentum := my_velocity.length() * mass
	var push_ratio := mass / total_mass
	var push_force := -collision_normal * my_momentum * push_ratio * 0.5
	
	return {
		"can_push": true,
		"push_force": push_force,
		"my_mass": mass,
		"other_mass": other_mass,
		"push_ratio": push_ratio
	}

func calculate_counter_push(other: Node2D, collision_normal: Vector2, other_velocity: Vector2, min_velocity: float = 10.0) -> Dictionary:
	if other_velocity.length() < min_velocity:
		return {"should_push": false}
	
	var other_component := EntityComponent.get_from(other)
	if not other_component:
		return {"should_push": false}
	
	var other_mass := other_component.mass
	var total_mass := mass + other_mass
	
	var other_momentum := other_velocity.length() * other_mass
	var counter_ratio := other_mass / total_mass
	var counter_push := collision_normal * other_momentum * counter_ratio * 0.5
	
	return {
		"should_push": true,
		"counter_push": counter_push,
		"other_mass": other_mass
	}


