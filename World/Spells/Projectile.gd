class_name Projectile
extends Area2D

signal impacted(body: Node2D)
signal expired

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var pierce: bool = false
@export var affected_by_forces: bool = true
@export var force_influence: float = 0.3  # How much forces affect velocity (0-1)
@export var debug_draw: bool = false

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
	velocity = direction * speed
	
	# Find ForceReceiver if exists
	for child in get_children():
		if child is ForceReceiver:
			_force_receiver = child
			break

func _physics_process(delta: float) -> void:
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

func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	
	impacted.emit(body)
	
	if not pierce:
		queue_free()
