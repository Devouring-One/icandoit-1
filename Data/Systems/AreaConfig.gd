class_name AreaConfig
extends SpellBehavior

@export_file("*.tscn") var area_scene_path: String = "res://World/Effects/explosion.tscn"
@export var radius: float = 100.0
@export var max_force: float = 400.0
@export var lifetime: float = 0.0
@export var can_affect_caster: bool = false
@export var falloff_exponent: float = 1.0

func get_area_scene() -> PackedScene:
	if area_scene_path and area_scene_path != "":
		return load(area_scene_path)
	return null

func cast(spell, caster: Node2D, target_position: Vector2, original_caster: Node2D = null) -> void:
	var real_original_caster: Node2D = original_caster if original_caster else caster
	var area_scene: PackedScene = get_area_scene()
	
	if not area_scene:
		push_error("AreaConfig: area_scene_path is not set or invalid")
		return
	
	var explosion: Explosion = area_scene.instantiate()
	explosion.global_position = target_position
	explosion.setup(radius, spell, spell.on_hit, real_original_caster, lifetime)
	caster.get_tree().current_scene.call_deferred("add_child", explosion)
	
	if spell.on_hit and spell.on_hit.nested_spells and spell.on_hit.nested_spells.size() > 0:
		for nested_resource in spell.on_hit.nested_spells:
			var nested = nested_resource
			if nested:
				nested.cast(caster, target_position, real_original_caster)
