class_name Explosion
extends Area2D

@export var max_damage: float = 5.0
@export var max_force: float = 100.0
@export var radius: float = 100.0
@export var force_base_duration: float = 2.0
@export var force_duration_coefficient: float = 0.0
@export var falloff_exponent: float = 1.0
@export var collision_layer_bits: int = 2
@export var collision_mask_bits: int = 5
@export var debug_color: Color = Color(0.75686276, 0.45490196, 0, 0.41960785)
@export var lifetime: float = 0.0

var caster: Node2D = null
var spell = null
var event_config: SpellEventConfig = null
var can_affect_caster: bool = false
var _collision_shape: CollisionShape2D
var _triggered: bool = false

func setup(new_radius: float, from_spell, on_hit_config: SpellEventConfig, from_caster: Node2D, area_lifetime: float = 0.0) -> void:
	radius = new_radius
	spell = from_spell
	event_config = on_hit_config
	caster = from_caster
	can_affect_caster = from_spell.can_affect_caster if from_spell else false
	lifetime = area_lifetime

func _ready() -> void:
	collision_layer = collision_layer_bits
	collision_mask = collision_mask_bits
	_ensure_collision_shape()
	_collision_shape.shape.radius = radius
	_collision_shape.debug_color = debug_color
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	_trigger_explosion()
	
	if lifetime <= 0.0:
		_collision_shape.disabled = true
		_collision_shape.debug_color = Color(1, 1, 0, 0.1)
		await get_tree().create_timer(0.5).timeout
		queue_free()
	else:
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_area_entered)
		await get_tree().create_timer(lifetime).timeout
		queue_free()

func _trigger_explosion() -> void:
	if _triggered:
		return
	_triggered = true
	
	for body in get_overlapping_bodies():
		_apply_to_target(body)
	
	for area in get_overlapping_areas():
		_apply_to_target(area)

func _on_body_entered(body: Node2D) -> void:
	_apply_to_target(body)

func _on_area_entered(area: Area2D) -> void:
	_apply_to_target(area)

func _apply_to_target(target: Node2D) -> void:
	if target == caster and not can_affect_caster:
		return
	
	var direction := (target.global_position - global_position)
	var center_distance := direction.length()
	
	if center_distance > 0:
		direction = direction.normalized()
	else:
		direction = Vector2.RIGHT
	
	var effective_distance := center_distance
	if target is CharacterBody2D or target is RigidBody2D:
		for child in target.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				effective_distance = max(0.0, center_distance - child.shape.radius)
				break
	
	var falloff = clamp(1.0 - (effective_distance / radius), 0.0, 1.0)
	falloff = pow(falloff, falloff_exponent)
	
	if spell and event_config:
		spell._trigger_event_with_falloff(event_config, self, global_position, target, caster, falloff)

func _ensure_collision_shape() -> void:
	if not is_instance_valid(_collision_shape):
		_collision_shape = CollisionShape2D.new()
		_collision_shape.unique_name_in_owner = true
		add_child(_collision_shape)
	if _collision_shape.shape == null:
		_collision_shape.shape = CircleShape2D.new()
