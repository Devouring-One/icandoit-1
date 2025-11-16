class_name Player
extends CharacterBody2D

@export var SPEED = 200
@export var FIREBALL_SCENE: PackedScene = preload("res://World/Spells/fireball.tscn")

var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _draw_node: Control = null

@onready var _entity_component: EntityComponent = %EntityComponent

func _ready() -> void:
	_draw_node = %DebugDrawLayer
	if not _draw_node:
		push_warning("DebugDrawLayer not found in scene")
		return
	
	_draw_node.draw.connect(_draw_target_marker)

	if not _entity_component:
		push_warning("EntityComponent not found; stats will not be shared")
	else:
		_entity_component.health_changed.connect(_on_health_changed)


func _clear_forces():
	if _entity_component:
		_entity_component.clear_forces()

func add_force(force: Force) -> void:
	if _entity_component:
		_entity_component.add_force(force)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var explosion: Explosion = Explosion.new()
			explosion.global_position = get_global_mouse_position()
			get_parent().add_child(explosion)
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_target_position = get_global_mouse_position()
			_has_target = true
			if _draw_node:
				_draw_node.queue_redraw()

	if event.is_action_pressed("spell_slot_1") and not event.is_echo():
		_cast_fireball()

func _draw_target_marker() -> void:
	if not _has_target or not _draw_node:
		return
	
	var size = 10.0
	var color = Color.GREEN
	var thickness = 2.0
	
	_draw_node.draw_line(_target_position + Vector2(-size, 0), _target_position + Vector2(size, 0), color, thickness)
	_draw_node.draw_line(_target_position + Vector2(0, -size), _target_position + Vector2(0, size), color, thickness)

func _get_forces_for_debug() -> Dictionary:
	if _entity_component:
		return _entity_component.get_debug_snapshot()
	return {}

func _physics_process(delta: float) -> void:
	var target_velocity = Vector2.ZERO
	var forces_velocity = Vector2.ZERO
	if _entity_component:
		forces_velocity = _entity_component.get_forces_velocity()
	
	var forces_magnitude = forces_velocity.length()
	var target_weight = 1.0
	if forces_magnitude > 0:
		target_weight = clamp(1.0 - (forces_magnitude / SPEED), 0.1, 1.0)
	
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
	
	if _entity_component:
		velocity = _entity_component.apply_forces_to(target_velocity)
	else:
		velocity = target_velocity + forces_velocity
	
	move_and_slide()

func _cast_fireball() -> void:
	var mouse_position = get_global_mouse_position()
	var direction = mouse_position - global_position
	if direction.length_squared() == 0.0:
		direction = Vector2.RIGHT

	var fireball: Fireball = FIREBALL_SCENE.instantiate()
	fireball.global_position = global_position
	fireball.launch(direction, self)
	get_parent().add_child(fireball)

func _on_regen_timer_timeout() -> void:
	if _entity_component:
		_entity_component.heal(1.0)

func apply_damage(amount: float) -> void:
	if not _entity_component:
		return
	_entity_component.apply_damage(amount)
	if _entity_component.get_health() <= 0.0:
		print("Player has died.")
		if has_node("%RegenTimer"):
			%RegenTimer.stop()

func _on_health_changed(_current: float, _max: float) -> void:
	pass  # hook for future VFX/logic
