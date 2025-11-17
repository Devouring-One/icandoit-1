class_name Projectile
extends Area2D

signal impacted(body: Node2D)
signal expired

@export var speed: float = 300.0
@export var lifetime: float = 5.0
@export var pierce: bool = false

var direction: Vector2 = Vector2.RIGHT
var caster: Node2D = null
var spell: Spell = null
var _lifetime_remaining: float = 0.0

func _ready() -> void:
	_lifetime_remaining = lifetime
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime_remaining -= delta
	
	if _lifetime_remaining <= 0.0:
		expired.emit()
		queue_free()

func setup(start_pos: Vector2, target_dir: Vector2, from_caster: Node2D, from_spell: Spell) -> void:
	global_position = start_pos
	direction = target_dir.normalized()
	caster = from_caster
	spell = from_spell
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body == caster:
		return
	
	impacted.emit(body)
	
	if not pierce:
		queue_free()
