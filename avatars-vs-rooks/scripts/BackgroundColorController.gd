extends ColorRect

@onready var tween: Tween = null
var last_scene: Node = null

func _ready():
	# Hacer que el ColorRect cubra toda la ventana sin importar el modo
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	# Que se expanda con la ventana
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# No bloquea clics ni interacciones
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Fondo detrás de todo
	z_index = -100

	# Aplicar color inicial
	color = GlobalSettings.background_color

	last_scene = get_tree().current_scene
	tween = create_tween()

	# Escuchar cambios de tamaño de ventana
	get_window().size_changed.connect(_on_window_resized)

	set_process(true)


func _process(_delta):
	# Detectar cambio de escena
	var current_scene = get_tree().current_scene
	if current_scene != last_scene and current_scene != null:
		last_scene = current_scene
		await get_tree().process_frame
		_apply_background_color()
		print("🔄 Escena cambiada, fondo actualizado.")

	# Detectar cambio de color global
	if color != GlobalSettings.background_color:
		_smooth_transition_to(GlobalSettings.background_color)


func _smooth_transition_to(new_color: Color):
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "color", new_color, 0.4)


func _apply_background_color():
	color = GlobalSettings.background_color
	_resize_to_window()


func _resize_to_window():
	# Asegura que el fondo siempre cubra toda la ventana visible
	var win_size: Vector2i = get_window().size
	size = Vector2(win_size.x, win_size.y)
	position = Vector2(0, 0)


func _on_window_resized():
	_resize_to_window()
