class_name HealthBarDisplay
extends Node2D

@export var show_label: bool = true
@export var label_format: String = "{current} / {max}"

var _current: float = 0.0
var _max: float = 1.0
var _progress_bar: ProgressBar = null
var _label: Label = null

func _ready() -> void:
	_progress_bar = %ProgressBar if has_node("%ProgressBar") else null
	_label = %HealthLabel if has_node("%HealthLabel") else null
	_update()

func set_health(current: float, max_value: float) -> void:
	_max = max(max_value, 0.001)
	_current = clamp(current, 0.0, _max)
	_update()

func _update() -> void:
	if is_instance_valid(_progress_bar):
		_progress_bar.max_value = _max
		_progress_bar.value = _current
	if is_instance_valid(_label):
		_label.visible = show_label
		if show_label:
			_label.text = label_format.format({
				"current": int(round(_current)),
				"max": int(round(_max))
			})