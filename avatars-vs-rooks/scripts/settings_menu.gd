extends Control

var current_user_uid: String = ""
var SAVE_PATH: String = ""

#@onready var resolution_option = $VBoxContainer/ResolutionOption
@onready var theme_option = $VBoxContainer/ThemeOption
@onready var color_buttons = [
	$VBoxContainer/ColorPickers/Color1,
	$VBoxContainer/ColorPickers/Color2,
	$VBoxContainer/ColorPickers/Color3,
	$VBoxContainer/ColorPickers/Color4,
	$VBoxContainer/ColorPickers/Color5
]
@onready var spotify_input = $VBoxContainer/SpotifyInput
@onready var music_toggle = $VBoxContainer/MusicToggle
@onready var volume_slider = $VBoxContainer/VolumeSlider
@onready var save_button = $VBoxContainer/SaveButton
@onready var SpotifyAPI = $"/root/SpotifyApi"

func _ready():
	# --- Configurar opciones ---
	#resolution_option.add_item("1280x720")
	#resolution_option.add_item("1920x1080")
	theme_option.add_item("Claro")
	theme_option.add_item("Oscuro")
	
	save_button.pressed.connect(_on_save_button_pressed)
	spotify_input.text_submitted.connect(_on_spotify_input_submitted)
	if GlobalSettings.current_user_uid != "":
		setup_for_user(GlobalSettings.current_user_uid)

	# Aplicar colores actuales desde GlobalSettings
	_update_preview_from_globals()


func setup_for_user(uid: String) -> void:
	current_user_uid = uid
	SAVE_PATH = "user://settings_%s.cfg" % uid
	load_settings()


# --- GUARDAR CONFIGURACIÓN ---
func _on_save_button_pressed() -> void:
	save_settings()
	apply_settings()
	await GlobalSettings.save_user_theme_to_firestore()
	await save_to_firestore()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func save_settings() -> void:
	var config = ConfigFile.new()
	#config.set_value("Display", "resolution_index", resolution_option.selected)
	config.set_value("Display", "theme_index", theme_option.selected)

	for i in range(color_buttons.size()):
		config.set_value("Colors", "color_%d" % i, color_buttons[i].color)

	config.set_value("Audio", "volume_db", volume_slider.value)
	config.set_value("Music", "enabled", music_toggle.pressed)
	config.set_value("Music", "spotify_url", spotify_input.text)
	config.save(SAVE_PATH)

	# Guardar también en memoria global
	GlobalSettings.current_settings = {
		"theme": theme_option.get_item_text(theme_option.selected),
		"volume_db": volume_slider.value,
		"music_enabled": music_toggle.pressed,
		"spotify_url": spotify_input.text,
		"colors": [
			color_buttons[0].color,
			color_buttons[1].color,
			color_buttons[2].color,
			color_buttons[3].color,
			color_buttons[4].color
		],
		#"resolution_index": resolution_option.selected
	}
	print("✅ Configuración guardada localmente:", SAVE_PATH)


# --- CARGAR CONFIGURACIÓN ---
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		print("⚠️ No existe configuración local. Usando valores por defecto.")
		return

	#resolution_option.select(config.get_value("Display", "resolution_index", 0))
	theme_option.select(config.get_value("Display", "theme_index", 0))

	for i in range(color_buttons.size()):
		color_buttons[i].color = config.get_value("Colors", "color_%d" % i, Color(1,1,1))

	volume_slider.value = config.get_value("Audio", "volume_db", 0)
	#music_toggle.toggled = config.get_value("Music", "enabled", false)
	spotify_input.text = config.get_value("Music", "spotify_url", "")

	apply_settings()


# --- APLICAR CONFIGURACIÓN VISUAL ---
func apply_settings() -> void:
	# 📺 Aplicar resolución
	#var res_text = resolution_option.get_item_text(resolution_option.selected)
	#var res_arr = res_text.split("x")
	#if res_arr.size() == 2:
		#get_window().size = Vector2i(int(res_arr[0]), int(res_arr[1]))

	# 🎨 Aplicar tema y colores
	if theme_option.selected == 0:
		GlobalSettings.set_theme_light()
	else:
		GlobalSettings.set_theme_dark()

	GlobalSettings.apply_custom_colors([
		color_buttons[0].color,
		color_buttons[1].color,
		color_buttons[2].color,
		color_buttons[3].color,
		color_buttons[4].color
	])

	# 🔊 Aplicar volumen
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_slider.value)
	if music_toggle.pressed:
		$VBoxContainer/StatusLabel.text = "🎵 Música habilitada. Escribe una canción y presiona Enter."
	else:
		$VBoxContainer/StatusLabel.text = "🎵 Música deshabilitada."
	

# --- SINCRONIZAR EN FIRESTORE ---
func save_to_firestore() -> void:
	if current_user_uid == "":
		return

	var project_id = "avatarsvsrooksproject"
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s?updateMask.fieldPaths=settings" % [project_id, current_user_uid]
	var headers = ["Content-Type: application/json"]

	var colors_array = []
	for btn in color_buttons:
		colors_array.append({"stringValue": btn.color.to_html()})

	var settings_data = {
		"fields": {
			"settings": {
				"mapValue": {
					"fields": {
						"theme": {"stringValue": theme_option.get_item_text(theme_option.selected)},
						"spotify_url": {"stringValue": spotify_input.text},
						"music_enabled": {"booleanValue": music_toggle.toggled},
						"colors": {"arrayValue": {"values": colors_array}},
						"volume_db": {"integerValue": str(volume_slider.value)},
						#"resolution_index": {"integerValue": str(resolution_option.selected)}
					}
				}
			}
		}
	}

	var body = JSON.stringify(settings_data)
	var request = HTTPRequest.new()
	add_child(request)
	request.request(url, headers, HTTPClient.METHOD_PATCH, body)
	print("☁️ Configuración sincronizada en Firestore para UID:", current_user_uid)


# --- Mostrar vista previa inicial ---
func _update_preview_from_globals():
	for i in range(color_buttons.size()):
		if i < GlobalSettings.current_settings["colors"].size():
			color_buttons[i].color = GlobalSettings.current_settings["colors"][i]

func _on_spotify_input_submitted(query: String) -> void:
	query = query.strip_edges()
	if query == "":
		$VBoxContainer/StatusLabel.text = "⚠️ Ingresa un nombre de canción."
		return

	if not music_toggle.pressed:
		$VBoxContainer/StatusLabel.text = "🎵 La música está deshabilitada."
		return

	$VBoxContainer/StatusLabel.text = "🔍 Buscando en Spotify..."
	print("Buscando canción:", query)

	var song_data = await SpotifyAPI.search_song(query)

	if song_data.is_empty():
		$VBoxContainer/StatusLabel.text = "❌ No se encontró la canción en Spotify."
	else:
		var song_url = song_data["external_urls"]["spotify"]
		$VBoxContainer/StatusLabel.text = "🎶 Abriendo: " + song_data["name"]
		OS.shell_open(song_url)
