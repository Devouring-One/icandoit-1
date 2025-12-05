class_name Player
extends CharacterBody2D

var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _is_dragging_target: bool = false
var _draw_node: Control = null
var _spell_cooldowns: Dictionary = {}

@export var all_spells: ResourceGroup
var spell_book: Array = []

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
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_dragging_target = true
			else:
				_is_dragging_target = false

	for i in 10:
		if event.is_action_pressed("spell_slot_%d" % (i + 1)) and not event.is_echo():
			_cast_spell(spell_book[i] if spell_book.size() > i else null)

func _process(_delta: float) -> void:
	if _is_dragging_target:
		_target_position = get_global_mouse_position()
		_has_target = true
		if _draw_node:
			_draw_node.queue_redraw()

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
		@warning_ignore("confusable_local_declaration")
		var collision := move_and_collide(velocity * delta)
		if collision:
			_handle_collision(collision, delta)
		return
	
	velocity = _entity_component.compute_velocity(_target_position, _has_target, delta)
	
	if _has_target and (_target_position - global_position).length() <= 2.0:
		global_position = _target_position
		_has_target = false
		if _draw_node:
			_draw_node.queue_redraw()
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		_handle_collision(collision, delta)

func _handle_collision(collision: KinematicCollision2D, delta: float) -> void:
	var collider := collision.get_collider()
	var normal := collision.get_normal()
	
	if collider is CharacterBody2D:
		var push_data := _entity_component.calculate_push_to(collider, normal, velocity)
		if push_data.can_push:
			var other_component := EntityComponent.get_from(collider)
			if other_component:
				other_component.apply_push(push_data.push_force, push_data.my_mass)
		
		var counter_data := _entity_component.calculate_counter_push(collider, normal, collider.velocity)
		if counter_data.should_push:
			_entity_component.apply_push(counter_data.counter_push, counter_data.other_mass)
		
		var slide_factor = 0.75 * (push_data.get("push_ratio", 0.5) if push_data.can_push else 0.5)
		var slide_velocity = velocity.slide(normal) * slide_factor
		velocity = slide_velocity
		move_and_collide(slide_velocity * delta)
	else:
		velocity = velocity.slide(normal)
		move_and_collide(velocity * delta)


func _cast_spell(spell) -> void:
	if spell == null:
		return
	
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if _spell_cooldowns.has(spell.name):
		if current_time < _spell_cooldowns[spell.name]:
			print("Spell %s is on cooldown" % spell.name)
			return
	
	var target_pos: Vector2 = get_global_mouse_position()
	
	if spell.cast_time > 0.0:
		if _entity_ui:
			_entity_ui.start_cast(spell.cast_time)
		await get_tree().create_timer(spell.cast_time).timeout
	
	spell.cast(self, target_pos)
	
	_spell_cooldowns[spell.name] = current_time + spell.cooldown

func _on_health_changed(_current: float, _max: float) -> void:
	pass

func _on_entity_died() -> void:
	print("Player has died.")
