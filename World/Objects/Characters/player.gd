class_name Player
extends CharacterBody2D

var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _draw_node: Control = null
var _spell_cooldowns: Dictionary = {}  # spell_name -> cooldown_end_time

@export var all_spells: ResourceGroup
var spell_book: Array[Spell] = []

@onready var _entity_component: EntityComponent = %EntityComponent
@onready var _entity_ui: EntityUIComponent = %EntityUIComponent

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
		_entity_component.died.connect(_on_entity_died)
	
	all_spells.load_all_into(spell_book)

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
		_cast_spell(spell_book[0] if spell_book.size() > 0 else null)
	
	if event.is_action_pressed("spell_slot_2") and not event.is_echo():
		_cast_spell(spell_book[1] if spell_book.size() > 1 else null)

func _draw_target_marker() -> void:
	if not _has_target or not _draw_node:
		return
	
	var size = 10.0
	var color = Color.GREEN
	var thickness = 2.0
	
	_draw_node.draw_line(_target_position + Vector2(-size, 0), _target_position + Vector2(size, 0), color, thickness)
	_draw_node.draw_line(_target_position + Vector2(0, -size), _target_position + Vector2(0, size), color, thickness)

func _physics_process(delta: float) -> void:
	if not _entity_component:
		move_and_slide()
		return
	
	velocity = _entity_component.compute_velocity(_target_position, _has_target, delta)
	
	if _has_target and (_target_position - global_position).length() <= 2.0:
		global_position = _target_position
		_has_target = false
		if _draw_node:
			_draw_node.queue_redraw()
	
	move_and_slide()


func _cast_spell(spell: Spell) -> void:
	if spell == null:
		return
	
	# Check cooldown
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if _spell_cooldowns.has(spell.name):
		if current_time < _spell_cooldowns[spell.name]:
			print("Spell %s is on cooldown" % spell.name)
			return
	
	# Capture target position BEFORE cast time
	var target_pos: Vector2 = get_global_mouse_position()
	
	# Apply cast time delay
	if spell.cast_time > 0.0:
		if _entity_ui:
			_entity_ui.start_cast(spell.cast_time)
		await get_tree().create_timer(spell.cast_time).timeout
	
	# Cast spell using captured position
	spell.cast(self, target_pos)
	
	# Set cooldown
	_spell_cooldowns[spell.name] = current_time + spell.cooldown

func _on_health_changed(_current: float, _max: float) -> void:
	pass  # hook for future VFX/logic

func _on_entity_died() -> void:
	print("Player has died.")
	if has_node("%RegenTimer"):
		%RegenTimer.stop()
