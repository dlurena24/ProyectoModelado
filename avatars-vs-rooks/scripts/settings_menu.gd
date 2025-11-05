extends Control

@onready var theme_option: OptionButton = $VBoxContainer/ThemeOption
@onready var color_pickers_container: Control = $VBoxContainer/ColorPickers
@onready var color1_btn: ColorPickerButton = $VBoxContainer/ColorPickers/Color1
@onready var color2_btn: ColorPickerButton = $VBoxContainer/ColorPickers/Color2
@onready var spotify_input: LineEdit = $VBoxContainer/SpotifyInput
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var music_toggle: CheckButton = $VBoxContainer/MusicToggle
@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var save_button: Button = $VBoxContainer/SaveButton

func _ready() -> void:
	# Opciones
	if theme_option.item_count == 0:
		theme_option.add_item("Oscuro")
		theme_option.add_item("Claro")
		theme_option.add_item("Personalizado")
	theme_option.item_selected.connect(_on_theme_changed)

	save_button.pressed.connect(_on_save_pressed)
	spotify_input.text_submitted.connect(_on_spotify_input_submitted)

	_load_from_globals()
	GlobalSettings.update_theme()

func _load_from_globals() -> void:
	var s: Dictionary = GlobalSettings.current_settings
	var theme: String = str(s.get("theme", "Oscuro"))

	# Seleccionar tema
	var idx: int = 0
	for i in range(theme_option.item_count):
		if theme_option.get_item_text(i) == theme:
			idx = i
			break
	theme_option.select(idx)
	_toggle_color_inputs(theme == "Personalizado")

	# Colores: solo 2
	var cols: Array = s.get("colors", [])
	if cols.size() >= 1:
		var c1: Variant = cols[0]
		color1_btn.color = c1 if c1 is Color else Color(str(c1))
	if cols.size() >= 2:
		var c2: Variant = cols[1]
		color2_btn.color = c2 if c2 is Color else Color(str(c2))

	# Otros
	spotify_input.text = str(s.get("spotify_url", ""))
	music_toggle.button_pressed = bool(s.get("music_enabled", false))
	volume_slider.value = float(s.get("volume_db", 0))

func _on_theme_changed(_i: int) -> void:
	var sel: String = theme_option.get_item_text(theme_option.selected)
	_toggle_color_inputs(sel == "Personalizado")

func _toggle_color_inputs(enabled: bool) -> void:
	color_pickers_container.modulate.a = 1.0 if enabled else 0.5
	color1_btn.disabled = not enabled
	color2_btn.disabled = not enabled

func _on_save_pressed() -> void:
	var theme_name: String = theme_option.get_item_text(theme_option.selected)

	# Guardar toggles/volumen/url
	GlobalSettings.current_settings["music_enabled"] = music_toggle.button_pressed
	GlobalSettings.current_settings["volume_db"] = int(volume_slider.value)
	GlobalSettings.current_settings["spotify_url"] = spotify_input.text

	if theme_name == "Claro":
		GlobalSettings.set_theme_light()
	elif theme_name == "Oscuro":
		GlobalSettings.set_theme_dark()
	else:
		# Personalizado → Color1 fondo, Color2 texto
		var palette: Array = [color1_btn.color, color2_btn.color]
		GlobalSettings.apply_palette_or_theme(palette, "Personalizado")

	await GlobalSettings.save_user_theme_to_firestore()
	GlobalSettings.update_theme()
	status_label.text = "✅ Configuración guardada"

	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_spotify_input_submitted(q: String) -> void:
	var query: String = q.strip_edges()
	if query.is_empty():
		status_label.text = "⚠️ Ingresa un nombre de canción."
		return
	OS.shell_open("https://open.spotify.com/search/" + query.uri_encode())
	status_label.text = "🔎 Buscando en Spotify…"
