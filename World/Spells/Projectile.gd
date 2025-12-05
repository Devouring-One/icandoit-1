class_name Projectile
extends Area2D

signal impacted(body: Node2D)
signal bounced(body: Node2D)
signal expired

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var pierce: bool = false
@export var can_affect_caster: bool = false
@export var affected_by_forces: bool = true
@export var force_influence: float = 0.3
@export var debug_draw: bool = false

var animate_speed: bool = false
var target_speed: float = 0.0
var speed_transition_duration: float = 1.0
var speed_trans_type: Tween.TransitionType = Tween.TRANS_LINEAR
var speed_ease_type: Tween.EaseType = Tween.EASE_IN_OUT
var _speed_tween: Tween = null

var can_bounce: bool = false
var max_bounces: int = 0
var bounce_from_bodies: bool = true
var bounce_from_projectiles: bool = false
var bounce_speed_multiplier: float = 1.0
var _bounces_remaining: int = 0

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var caster: Node2D = null
var original_caster: Node2D = null
var spell = null
var _lifetime_remaining: float = 0.0
var _force_receiver: ForceReceiver = null
var _last_force_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	_lifetime_remaining = lifetime
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	velocity = direction * speed
	
	if animate_speed:
		_speed_tween = create_tween()
		_speed_tween.tween_property(self, "speed", target_speed, speed_transition_duration).set_trans(speed_trans_type).set_ease(speed_ease_type)
	
	for child in get_children():
		if child is ForceReceiver:
			_force_receiver = child
			break

func _physics_process(delta: float) -> void:
	if animate_speed:
		var current_speed: float = velocity.length()
		if not is_equal_approx(current_speed, speed):
			velocity = direction * speed
	
	if affected_by_forces and _force_receiver:
		var forces_velocity: Vector2 = _force_receiver.get_forces_velocity()
		
		if forces_velocity.length_squared() > 1.0:
			_last_force_direction = forces_velocity.normalized()
			velocity += forces_velocity * force_influence
			
			direction = velocity.normalized()
			rotation = direction.angle()
			
			_force_receiver.clear_forces()
			
			if debug_draw:
				queue_redraw()
		else:
			_last_force_direction = Vector2.ZERO
	
	position += velocity * delta
	
	_lifetime_remaining -= delta
	
	if _lifetime_remaining <= 0.0:
		expired.emit()
		queue_free()

func _draw() -> void:
	if not debug_draw:
		return
	
	var arrow_length: float = 50.0
	var world_vel: Vector2 = velocity.normalized().rotated(-rotation)
	draw_line(Vector2.ZERO, world_vel * arrow_length, Color.YELLOW, 2.0)
	
	if _last_force_direction.length_squared() > 0.1:
		var world_force: Vector2 = _last_force_direction.rotated(-rotation)
		draw_line(Vector2.ZERO, world_force * arrow_length * 0.5, Color.RED, 2.0)

func setup(start_pos: Vector2, target_dir: Vector2, from_caster: Node2D, from_spell, from_original_caster: Node2D = null) -> void:
	global_position = start_pos
	direction = target_dir.normalized()
	velocity = direction * speed
	caster = from_caster
	original_caster = from_original_caster if from_original_caster else from_caster
	spell = from_spell
	rotation = direction.angle()
	_bounces_remaining = max_bounces

func _on_body_entered(body: Node2D) -> void:
	if not can_affect_caster and (body == caster or body == original_caster):
		return
	
	_handle_collision(body, true)

func _on_area_entered(area: Area2D) -> void:
	if area == self or area == caster or area == original_caster:
		return
	
	if not area is Projectile:
		return
	
	_handle_collision(area, false)

func _handle_collision(collider: Node2D, is_body: bool) -> void:
	var should_bounce := false
	if can_bounce and (_bounces_remaining > 0 or max_bounces == -1):
		if is_body:
			should_bounce = bounce_from_bodies
		else:
			should_bounce = bounce_from_projectiles
	
	if should_bounce:
		_handle_bounce(collider)
	else:
		impacted.emit(collider)
		if not pierce:
			queue_free()

func _handle_bounce(collider: Node2D) -> void:
	var to_collider: Vector2 = collider.global_position - global_position
	var collision_point: Vector2 = global_position + velocity.normalized() * 8.0
	
	var normal: Vector2 = (global_position - collision_point).normalized()
	
	if to_collider.length_squared() > 0.01:
		normal = -to_collider.normalized()
	else:
		normal = -velocity.normalized()
	
	var reflected: Vector2 = velocity.bounce(normal)
	velocity = reflected * bounce_speed_multiplier
	direction = velocity.normalized()
	rotation = direction.angle()
	
	if max_bounces != -1:
		_bounces_remaining -= 1
	
	bounced.emit(collider)
