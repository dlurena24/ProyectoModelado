extends Control

# Carpeta de donde se cargarán las imágenes automáticamente si slide_paths está vacío
const SLIDES_FOLDER := "res://assets/tutorial"
# A dónde ir al terminar / saltar el tutorial
const RETURN_SCENE  := "res://scenes/game.tscn"
# A donde ir al terminar la ultima imagen del turioral
const MENU_SCENE := "res://scenes/main_menu.tscn"

# Si prefieres definir manualmente el orden, llena este array y deja la carpeta vacía.
var slide_paths: Array[String] = []  # ej: ["res://assets/tutorial/01_intro.png", "res://assets/tutorial/02_controles.png"]

var slides: Array[Texture2D] = []
var index: int = 0

@onready var title_label: Label = $Margin/VBox/Title
@onready var img: TextureRect = $Margin/VBox/SlideFrame/SlideBox/SlideTexture
@onready var prev_btn: Button = $Margin/VBox/Footer/PrevButton
@onready var next_btn: Button = $Margin/VBox/Footer/NextButton
@onready var skip_btn: Button = $Margin/VBox/Footer/SkipButton
@onready var play_btn: Button = $Margin/VBox/Footer/PlayButton
@onready var page_label: Label = $Margin/VBox/Footer/PageLabel

func _ready() -> void:
	title_label.text = "Tutorial"
	_connect_ui()
	_load_slides()
	_update_ui()
	GlobalSettings.update_theme()

func _connect_ui() -> void:
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	skip_btn.pressed.connect(_on_finish)
	play_btn.pressed.connect(_on_finish)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_on_prev()
	elif event.is_action_pressed("ui_right"):
		_on_next()
	elif event.is_action_pressed("ui_accept"):
		if index >= slides.size() - 1:
			_on_finish()
		else:
			_on_next()

# ----------------- Carga de slides -----------------
func _load_slides() -> void:
	slides.clear()

	var paths: Array[String] = []
	if slide_paths.size() > 0:
		paths = slide_paths.duplicate()
	else:
		paths = _load_paths_from_folder(SLIDES_FOLDER)

	# Cargar Texturas
	for p in paths:
		var tex: Texture2D = load(p) as Texture2D
		if tex != null:
			slides.append(tex)

	if slides.is_empty():
		# No hay imágenes → placeholder
		var img_res := Image.create(800, 450, false, Image.FORMAT_RGBA8)
		img_res.fill(Color.DARK_GRAY)
		var t := ImageTexture.create_from_image(img_res)
		slides.append(t)

	index = 0

func _load_paths_from_folder(folder: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(folder)
	if dir == null:
		return out
	dir.list_dir_begin()
	while true:
		var f: String = dir.get_next()
		if f == "":
			break
		if dir.current_is_dir():
			continue
		var low := f.to_lower()
		if low.ends_with(".png") or low.ends_with(".jpg") or low.ends_with(".jpeg") or low.ends_with(".webp"):
			out.append(folder + "/" + f)
	dir.list_dir_end()
	out.sort()  # orden alfabético
	return out

# ----------------- Navegación -----------------
func _on_prev() -> void:
	if index > 0:
		index -= 1
	_update_ui()

func _on_next() -> void:
	if index < slides.size() - 1:
		index += 1
		_update_ui()
	else:
		# en la última, "Siguiente" equivale a jugar
		_on_finish()

func _on_finish() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

# ----------------- UI -----------------
func _update_ui() -> void:
	# imagen actual
	if index >= 0 and index < slides.size():
		img.texture = slides[index]

	# estados de botones
	prev_btn.disabled = (index <= 0)
	next_btn.disabled = (slides.size() <= 0)
	next_btn.text = "Menu" if index >= slides.size() - 1 else "Siguiente"

	# "Jugar" siempre visible
	play_btn.visible = true

	# página
	page_label.text = "%d / %d" % [index + 1, max(1, slides.size())]
