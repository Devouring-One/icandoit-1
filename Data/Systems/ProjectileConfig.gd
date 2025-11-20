class_name ProjectileConfig
extends Resource

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var pierce: bool = false
@export var affected_by_forces: bool = true
@export var force_influence: float = 0.3

@export_group("Multi-shot")
@export var projectile_count: int = 1
@export_range(0, 180, 1, "radians_as_degrees") var spread_angle: float = 0.0
