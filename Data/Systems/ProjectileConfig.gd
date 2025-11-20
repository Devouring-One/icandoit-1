class_name ProjectileConfig
extends Resource

@export var speed: float = 300.0
@export var lifetime: float = 2.0
@export var pierce: bool = false
@export var affected_by_forces: bool = true
@export var force_influence: float = 0.3

@export_group("Speed Animation")
@export var animate_speed: bool = false
@export var target_speed: float = 600.0
@export var speed_transition_duration: float = 0
@export var speed_trans_type: Tween.TransitionType = Tween.TRANS_LINEAR
@export var speed_ease_type: Tween.EaseType = Tween.EASE_IN_OUT

@export_group("Bounce")
@export var can_bounce: bool = false
@export var max_bounces: int = 3  ## 0 = no bounces, -1 = infinite
@export var bounce_from_bodies: bool = true
@export var bounce_from_projectiles: bool = false
@export var bounce_speed_multiplier: float = 1.0  ## Speed after bounce (1.0 = same speed)

@export_group("Multi-shot")
@export var projectile_count: int = 1
@export var omnidirectional: bool = false
@export_range(0, 180, 1, "radians_as_degrees") var spread_angle: float = 0.0
