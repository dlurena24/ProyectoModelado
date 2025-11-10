extends Control

const BACKGROUND_PATH := "res://assets/fondo .png" 

@onready var play_button: Button = $Control/PlayButton
@onready var settings_button: Button = $Control2/SettingsButton
@onready var quit_button: Button = $Control5/QuitButton

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var hof_button: Button = $Control3/HallOfFameButton  # crea o toma el botón de Salón de la Fama
@onready var tutorial_button: Button = $Control4/TutorialButton  

@onready var header: HBoxContainer = $Header
@onready var avatar_tex: TextureRect = _resolve_avatar()
@onready var username_label: Label = $Header/VBoxContainer/UsernameLabel
@onready var full_name_label: Label = $Header/VBoxContainer/FullNameLabel
@onready var name_box: VBoxContainer = $Header/VBoxContainer

# Fondo
@onready var background_tex: TextureRect = _ensure_background()

const AVATAR_SIZE := Vector2(86, 86)
const HEADER_HEIGHT := 86

func _ready() -> void:
	# Botones existentes
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# Salón de la Fama
	if not hof_button.pressed.is_connected(_on_hof_button_pressed):
		hof_button.pressed.connect(_on_hof_button_pressed)

	# Tutorial (tu botón ya está en la escena)
	if tutorial_button and not tutorial_button.pressed.is_connected(_on_tutorial_button_pressed):
		tutorial_button.pressed.connect(_on_tutorial_button_pressed)

	_setup_header_bounds()
	_setup_avatar_bounds()
	_setup_name_box_flags()

	# Cargar imagen de fondo si existe el recurso
	if ResourceLoader.exists(BACKGROUND_PATH):
		var tex: Texture2D = load(BACKGROUND_PATH) as Texture2D
		if tex:
			background_tex.texture = tex

	# Si tienes un ColorRect tapando el fondo, lo ocultamos (opcional)
	var cr: ColorRect = get_node_or_null("ColorRect") as ColorRect
	if cr:
		cr.visible = false   # o usa cr.modulate.a = 0.25 para tinte semitransparente

	GlobalSettings.user_profile_changed.connect(_apply_profile_ui)
	if GlobalSettings.user_profile.is_empty() and GlobalSettings.current_user_uid != "":
		await GlobalSettings.load_user_profile(GlobalSettings.current_user_uid)

	_apply_profile_ui(GlobalSettings.user_profile)
	GlobalSettings.update_theme()

func _resolve_avatar() -> TextureRect:
	var a: TextureRect = get_node_or_null("Header/Avatar") as TextureRect
	if a == null:
		a = get_node_or_null("Header/AvatarFrame/Avatar") as TextureRect
	return a

func _ensure_hof_button() -> Button:
	var b: Button = vbox.get_node_or_null("HallOfFameButton") as Button
	if b != null:
		return b
	# Crear el botón si no existe
	b = Button.new()
	b.name = "HallOfFameButton"
	b.text = "Salón de la Fama"
	vbox.add_child(b)
	# Intentar colocarlo antes de Quit
	var idx_quit := vbox.get_children().find(quit_button)
	if typeof(idx_quit) == TYPE_INT and int(idx_quit) >= 0:
		vbox.move_child(b, int(idx_quit))
	return b

func _ensure_background() -> TextureRect:
	# Crea (o usa) un TextureRect llamado "Background" como PRIMER hijo para que quede al fondo
	var bg: TextureRect = get_node_or_null("Background") as TextureRect
	if bg == null:
		bg = TextureRect.new()
		bg.name = "Background"
		add_child(bg)
		move_child(bg, 0)  # índice 0 = dibujado primero (detrás)
	# Anclas a pantalla completa
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	# No intercepta clics
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ajuste de imagen al tamaño de ventana
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Si prefieres que no recorte y deje bandas negras:
	# bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bg.z_index = -100
	return bg

func _setup_header_bounds() -> void:
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 0
	header.offset_left = 0
	header.offset_right = 0
	header.size.y = HEADER_HEIGHT
	header.custom_minimum_size.y = HEADER_HEIGHT
	header.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _setup_avatar_bounds() -> void:
	if avatar_tex == null:
		return
	avatar_tex.custom_minimum_size = AVATAR_SIZE
	avatar_tex.size = AVATAR_SIZE
	avatar_tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar_tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar_tex.set_anchors_preset(Control.PRESET_CENTER)
	avatar_tex.position = Vector2.ZERO

func _setup_name_box_flags() -> void:
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	username_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	full_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _on_hof_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hall_of_fame.tscn")

func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _apply_profile_ui(p: Dictionary) -> void:
	# Defaults seguros
	username_label.text = "@Invitado"
	full_name_label.visible = false
	if avatar_tex:
		avatar_tex.visible = false

	if p.is_empty():
		return

	var uname: String = str(p.get("username","")).strip_edges()
	if uname.is_empty():
		username_label.text = "@Invitado"
	else:
		username_label.text = "@" + uname

	var role: String = str(p.get("role", "user"))
	var name: String = str(p.get("name", "")).strip_edges()
	full_name_label.visible = (role == "admin") and not name.is_empty()
	if full_name_label.visible:
		full_name_label.text = name

	var photo_url: String = str(p.get("profile_picture_url", ""))
	var photo_path: String = str(p.get("profile_picture_path", ""))
	if avatar_tex:
		if not photo_url.is_empty():
			avatar_tex.visible = true
			await _http_into_texture(photo_url)
		elif not photo_path.is_empty():
			avatar_tex.visible = true
			var ok: bool = await _load_from_storage(photo_path)
			if not ok:
				avatar_tex.visible = false

	_setup_header_bounds()
	_setup_avatar_bounds()
	_setup_name_box_flags()

func _http_into_texture(url: String) -> void:
	if avatar_tex == null:
		return
	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)
	var err: int = req.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		req.queue_free()
		return
	var args: Array = await req.request_completed
	req.queue_free()
	if args.size() < 4:
		return
	var body: PackedByteArray = args[3]
	var img: Image = Image.new()
	if img.load_png_from_buffer(body) != OK:
		if img.load_jpg_from_buffer(body) != OK:
			return
	avatar_tex.texture = ImageTexture.create_from_image(img)

func _load_from_storage(path: String) -> bool:
	if not Firebase or not Firebase.Storage or avatar_tex == null:
		return false
	var url_var: Variant = await Firebase.Storage.get_download_url(path)
	var url: String = str(url_var)
	if url.is_empty():
		return false
	await _http_into_texture(url)
	return avatar_tex.texture != null
