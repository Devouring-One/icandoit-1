class_name RaycastConfig
extends Resource

@export var max_range: float = 1000.0
@export var collision_mask: int = 1
@export var pierce: bool = false
@export var pierce_count: int = 0  # 0 = infinite when pierce=true
