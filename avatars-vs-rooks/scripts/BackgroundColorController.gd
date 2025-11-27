extends ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -10000

func _process(_delta: float) -> void:
	color = GlobalSettings.background_color

func _resize_to_window() -> void:
	var win_size: Vector2i = get_window().size
	size = Vector2(win_size.x, win_size.y)
	position = Vector2.ZERO

func _on_window_resized() -> void:
	_resize_to_window()
