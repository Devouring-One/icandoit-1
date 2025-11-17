class_name EntityUIComponent
extends Node2D

@export_group("Health Bar")
@export var show_health_bar: bool = true
@export var health_bar_offset: Vector2 = Vector2(0, -48)
@export var health_bar_size: Vector2 = Vector2(64, 6)
@export var health_bar_color: Color = Color.GREEN
@export var show_health_label: bool = true

@export_group("Cast Bar")
@export var show_cast_bar: bool = true
@export var cast_bar_offset: Vector2 = Vector2(0, -56)
@export var cast_bar_size: Vector2 = Vector2(64, 3)
@export var cast_bar_color: Color = Color.YELLOW

@export_group("Force Debug")
@export var show_force_debug: bool = true
@export var force_scale_factor: float = 0.2
@export var show_individual_forces: bool = true
@export var show_sum_forces: bool = true
@export var show_velocity: bool = true

var _current_health: float = 0.0
var _max_health: float = 1.0
var _cast_progress: float = 0.0
var _is_casting: bool = false
var _owner_body: Node = null
var _entity_component: EntityComponent = null

func _ready() -> void:
	_owner_body = get_parent()
	if _owner_body:
		for child in _owner_body.get_children():
			if child is EntityComponent:
				_entity_component = child
				break
	
	if _entity_component:
		_entity_component.health_changed.connect(_on_health_changed)
		_current_health = _entity_component.health
		_max_health = _entity_component.max_health
	else:
		push_warning("EntityUIComponent: EntityComponent not found on parent")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw health bar
	if show_health_bar:
		var health_percent: float = _current_health / _max_health if _max_health > 0.0 else 0.0
		
		# Center the bar horizontally
		var bar_x_offset: float = -health_bar_size.x * 0.5
		var bar_pos: Vector2 = health_bar_offset + Vector2(bar_x_offset, 0)
		
		# Background
		draw_rect(Rect2(bar_pos, health_bar_size), Color(0.2, 0.2, 0.2, 0.8))
		
		# Health bar with color gradient
		var bar_color: Color = health_bar_color
		if health_percent > 0.5:
			bar_color = Color.GREEN.lerp(Color.YELLOW, (1.0 - health_percent) * 2.0)
		else:
			bar_color = Color.YELLOW.lerp(Color.RED, (0.5 - health_percent) * 2.0)
		
		var bar_width: float = health_bar_size.x * health_percent
		draw_rect(Rect2(bar_pos, Vector2(bar_width, health_bar_size.y)), bar_color)
		
		# Label with better readability
		if show_health_label:
			var label_text: String = "%d / %d" % [int(_current_health), int(_max_health)]
			var font: Font = ThemeDB.fallback_font
			var font_size: int = 11
			
			# Calculate text width to center it properly
			var text_width: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var label_pos: Vector2 = health_bar_offset + Vector2(-text_width * 0.5, -4)
			
			# Draw black outline (8 directions for better quality)
			for offset in [
				Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
				Vector2(-1, 0), Vector2(1, 0),
				Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)
			]:
				draw_string(font, label_pos + offset, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
			
			# Draw white text on top
			draw_string(font, label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Draw cast bar
	if show_cast_bar and _is_casting:
		# Center the cast bar horizontally
		var cast_x_offset: float = -cast_bar_size.x * 0.5
		var cast_pos: Vector2 = cast_bar_offset + Vector2(cast_x_offset, 0)
		
		# Background
		draw_rect(Rect2(cast_pos, cast_bar_size), Color(0.2, 0.2, 0.2, 0.8))
		
		# Progress
		var cast_width: float = cast_bar_size.x * _cast_progress
		draw_rect(Rect2(cast_pos, Vector2(cast_width, cast_bar_size.y)), cast_bar_color)
	
	# Draw force debug arrows
	if show_force_debug and _entity_component:
		var debug_data: Dictionary = _entity_component.get_debug_snapshot()
		var thickness: float = 2.0
		
		if show_individual_forces and debug_data.has("forces"):
			for force in debug_data.forces:
				var force_vec: Vector2 = force.get_current_force()
				if force_vec != Vector2.ZERO:
					draw_line(Vector2.ZERO, force_vec * force_scale_factor, Color.YELLOW, thickness * 0.7)
		
		if show_sum_forces and debug_data.has("forces_velocity"):
			var forces_velocity: Vector2 = debug_data.forces_velocity
			if forces_velocity != Vector2.ZERO:
				draw_line(Vector2.ZERO, forces_velocity * force_scale_factor, Color.RED, thickness)
		
		if debug_data.has("target_velocity"):
			var target_velocity: Vector2 = debug_data.target_velocity
			if target_velocity != Vector2.ZERO:
				draw_line(Vector2.ZERO, target_velocity * force_scale_factor, Color.GREEN, thickness)
		
		if show_velocity and debug_data.has("velocity"):
			var velocity: Vector2 = debug_data.velocity
			if velocity != Vector2.ZERO:
				draw_line(Vector2.ZERO, velocity * force_scale_factor, Color.CYAN, thickness)
	elif show_force_debug and not _entity_component:
		# Debug: draw a small red circle if component is missing
		draw_circle(Vector2.ZERO, 5.0, Color.RED)

func start_cast(duration: float) -> void:
	if not show_cast_bar or duration <= 0.0:
		return
	
	_is_casting = true
	_cast_progress = 0.0
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "_cast_progress", 1.0, duration).from(0.0)
	tween.finished.connect(func(): 
		_is_casting = false
	)

func cancel_cast() -> void:
	_is_casting = false
	_cast_progress = 0.0
	var tweens: Array[Tween] = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween.is_valid():
			tween.kill()

func _on_health_changed(current: float, max_value: float) -> void:
	_current_health = current
	_max_health = max_value
