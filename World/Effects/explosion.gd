class_name Explosion
extends Area2D

@export var max_damage: float = 10.0
@export var max_force: float = 100.0
@export var radius: float = 400.0
@export var force_base_duration: float = 2.0  ## Base duration for all forces
@export var force_duration_coefficient: float = 0.0  ## Extra duration per force magnitude (0 = disabled)
@export var falloff_exponent: float = 1.0  ## 1.0 = linear, 2.0 = quadratic, 0.5 = square root

func _ready() -> void:
    %CollisionShape2D.shape.radius = radius
    %CollisionShape2D.debug_color = Color.RED
    
    await get_tree().physics_frame
    await get_tree().physics_frame
    
    for body in get_overlapping_bodies():
        _apply_explosion(body)
    
    %CollisionShape2D.disabled = true
    %CollisionShape2D.debug_color = Color(1, 1, 0, 0.1)

    await get_tree().create_timer(.5).timeout
    queue_free()

func _apply_explosion(body: Node2D) -> void:
    var direction = (body.global_position - global_position)
    var center_distance = direction.length()
    
    if center_distance > 0:
        direction = direction.normalized()
    else:
        direction = Vector2.RIGHT
    
    var effective_distance = center_distance
    if body is CharacterBody2D or body is RigidBody2D:
        for child in body.get_children():
            if child is CollisionShape2D and child.shape is CircleShape2D:
                effective_distance = max(0.0, center_distance - child.shape.radius)
                break
    
    var falloff = clamp(1.0 - (effective_distance / radius), 0.0, 1.0)
    falloff = pow(falloff, falloff_exponent)
    
    if body.has_method("take_damage"):
        body.take_damage(max_damage * falloff)
    
    if body.has_method("add_force"):
        var force = Force.new(
            direction,
            max_force * falloff,
            force_base_duration,
            body,
            force_duration_coefficient,
            Tween.TRANS_SINE,
            Tween.EASE_OUT
        )
        body.add_force(force)