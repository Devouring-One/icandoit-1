class_name Projectile
extends Area2D

signal impacted(body: Node2D)
signal bounced(body: Node2D)
signal expired

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var pierce: bool = false
@export var affected_by_forces: bool = true
@export var force_influence: float = 0.3  # How much forces affect velocity (0-1)
@export var debug_draw: bool = false

# Speed animation (set from ProjectileConfig)
var animate_speed: bool = false
var target_speed: float = 0.0
var speed_transition_duration: float = 1.0
var speed_trans_type: Tween.TransitionType = Tween.TRANS_LINEAR
var speed_ease_type: Tween.EaseType = Tween.EASE_IN_OUT
var _speed_tween: Tween = null

# Bounce settings (set from ProjectileConfig)
var can_bounce: bool = false
var max_bounces: int = 0
var bounce_from_bodies: bool = true
var bounce_from_projectiles: bool = false
var bounce_speed_multiplier: float = 1.0
var _bounces_remaining: int = 0
var _last_collision_normal: Vector2 = Vector2.ZERO

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO  # Current velocity vector
var caster: Node2D = null
var spell: Spell = null
var _lifetime_remaining: float = 0.0
var _force_receiver: ForceReceiver = null
var _last_force_direction: Vector2 = Vector2.ZERO  # For debug drawing

func _ready() -> void:
	_lifetime_remaining = lifetime
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	velocity = direction * speed
	
	# Setup speed animation
	if animate_speed:
		_speed_tween = create_tween()
		_speed_tween.tween_property(self, "speed", target_speed, speed_transition_duration).set_trans(speed_trans_type).set_ease(speed_ease_type)
	
	# Find ForceReceiver if exists
	for child in get_children():
		if child is ForceReceiver:
			_force_receiver = child
			break

func _physics_process(delta: float) -> void:
	# Update velocity magnitude if speed changed (from tween)
	if animate_speed:
		var current_speed: float = velocity.length()
		if not is_equal_approx(current_speed, speed):
			velocity = direction * speed
	
	# Apply forces if component exists
	if affected_by_forces and _force_receiver:
		var forces_velocity: Vector2 = _force_receiver.get_forces_velocity()
		
		# If there are forces, add them to velocity
		if forces_velocity.length_squared() > 1.0:
			_last_force_direction = forces_velocity.normalized()
			velocity += forces_velocity * force_influence
			
			# Update direction based on new velocity
			direction = velocity.normalized()
			rotation = direction.angle()
			
			# Clear forces to prevent decay (instant impulse)
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
	
	# Draw current velocity direction (rotated back to world space)
	var arrow_length: float = 50.0
	var world_vel: Vector2 = velocity.normalized().rotated(-rotation)
	draw_line(Vector2.ZERO, world_vel * arrow_length, Color.YELLOW, 2.0)
	
	# Draw force direction if any
	if _last_force_direction.length_squared() > 0.1:
		var world_force: Vector2 = _last_force_direction.rotated(-rotation)
		draw_line(Vector2.ZERO, world_force * arrow_length * 0.5, Color.RED, 2.0)

func setup(start_pos: Vector2, target_dir: Vector2, from_caster: Node2D, from_spell: Spell) -> void:
	global_position = start_pos
	direction = target_dir.normalized()
	velocity = direction * speed
	caster = from_caster
	spell = from_spell
	rotation = direction.angle()
	_bounces_remaining = max_bounces

func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	
	_handle_collision(body, true)

func _on_area_entered(area: Area2D) -> void:
	if area == self or area == caster:
		return
	
	_handle_collision(area, false)

func _handle_collision(collider: Node2D, is_body: bool) -> void:
	# Check if should bounce
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
	# Calculate normal from velocity direction and collider position
	var to_collider: Vector2 = collider.global_position - global_position
	var collision_point: Vector2 = global_position + velocity.normalized() * 8.0  # Approximate collision point
	
	# Calculate normal (perpendicular to collision surface)
	var normal: Vector2 = (global_position - collision_point).normalized()
	
	# Better approach: use perpendicular to the line connecting centers
	if to_collider.length_squared() > 0.01:
		normal = -to_collider.normalized()
	else:
		# Fallback: bounce straight back
		normal = -velocity.normalized()
	
	# Reflect velocity across normal
	var reflected: Vector2 = velocity.bounce(normal)
	velocity = reflected * bounce_speed_multiplier
	direction = velocity.normalized()
	rotation = direction.angle()
	
	# Decrement bounces
	if max_bounces != -1:
		_bounces_remaining -= 1
	
	bounced.emit(collider)
