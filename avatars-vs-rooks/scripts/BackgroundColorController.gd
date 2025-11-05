extends ColorRect

func _ready() -> void:
	anchor_left = 0.0; anchor_top = 0.0; anchor_right = 1.0; anchor_bottom = 1.0
	offset_left = 0.0; offset_top = 0.0; offset_right = 0.0; offset_bottom = 0.0
	_resize_to_window()
	get_window().size_changed.connect(_on_window_resized)
	set_process(true)

func _process(_delta: float) -> void:
	color = GlobalSettings.background_color

func _resize_to_window() -> void:
	var win_size: Vector2i = get_window().size
	size = Vector2(win_size.x, win_size.y)
	position = Vector2.ZERO

func _on_window_resized() -> void:
	_resize_to_window()
