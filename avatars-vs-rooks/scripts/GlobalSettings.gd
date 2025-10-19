extends Node

const DEFAULT_SETTINGS = {
	"theme": "Claro",
	"volume_db": 0,
	"music_enabled": false,
	"spotify_url": "",
	"colors": [],
	"resolution_index": 0
}

var background_color: Color = Color.BLACK
var text_color: Color = Color.WHITE
var current_user_uid: String = ""
var current_settings: Dictionary = DEFAULT_SETTINGS.duplicate()

# --- Reiniciar configuración por defecto ---
func reset_to_defaults():
	current_settings = DEFAULT_SETTINGS.duplicate()
	print("⚙️ GlobalSettings reseteado a valores por defecto.")
	set_theme_dark()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), current_settings.volume_db)

# --- TEMAS BASE ---
func set_theme_light():
	current_settings["theme"] = "Claro"
	if current_settings["colors"].is_empty():
		background_color = Color(0.95, 0.95, 0.95) # Fondo blanco
		text_color = Color(0.1, 0.1, 0.1)          # Texto negro
	update_theme()

func set_theme_dark():
	current_settings["theme"] = "Oscuro"
	if current_settings["colors"].is_empty():
		background_color = Color(0.08, 0.08, 0.08) # Fondo negro
		text_color = Color(1, 1, 1)                # Texto blanco
	update_theme()

# --- Colores personalizados ---
func apply_custom_colors(colors: Array):
	if colors.size() >= 2:
		current_settings["colors"] = colors
		background_color = colors[0]
		text_color = colors[1]
	update_theme()

# --- Aplicar visualmente ---
func update_theme():
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", background_color)

	for node in get_tree().get_nodes_in_group("ui_text"):
		if node is Label or node is Button or node is RichTextLabel or node is CheckButton or node is OptionButton or node is LineEdit:
			node.add_theme_color_override("font_color", text_color)

# --- Guardar tema en Firestore ---
func save_user_theme_to_firestore() -> void:
	if current_user_uid.is_empty():
		return

	var project_id = "avatarsvsrooksproject"
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [project_id, current_user_uid]
	var headers = ["Content-Type: application/json"]

	var data = {
		"fields": {
			"theme": {"stringValue": current_settings["theme"]},
			"theme_background": {"stringValue": background_color.to_html()},
			"theme_text": {"stringValue": text_color.to_html()}
		}
	}

	var body = JSON.stringify(data)
	var request := HTTPRequest.new()
	add_child(request)
	await request.request(url, headers, HTTPClient.METHOD_PATCH, body)
	print("🎨 Tema guardado para UID:", current_user_uid)
	request.queue_free()

# --- Cargar tema ---
func load_user_theme_from_firestore(uid: String):
	current_user_uid = uid
	var project_id = "avatarsvsrooksproject"
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [project_id, uid]
	var headers = ["Content-Type: application/json"]

	var request := HTTPRequest.new()
	add_child(request)
	var err = request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Error al iniciar HTTPRequest (load_user_theme)")
		request.queue_free()
		return

	var signal_args: Array = await request.request_completed
	var body_bytes: PackedByteArray = signal_args[3]
	var json_text: String = body_bytes.get_string_from_utf8()
	var data: Variant = JSON.parse_string(json_text)
	request.queue_free()

	if data == null or not data.has("fields"):
		print("⚠️ No se encontraron datos de tema en Firestore. Cargando por defecto.")
		reset_to_defaults()
		return

	var fields: Dictionary = data["fields"]
	if fields.has("theme"):
		current_settings["theme"] = fields["theme"]["stringValue"]

	if fields.has("theme_background"):
		background_color = Color(fields["theme_background"]["stringValue"])

	if fields.has("theme_text"):
		text_color = Color(fields["theme_text"]["stringValue"])

	# Aplicar tema correspondiente
	if current_settings["theme"] == "Claro":
		set_theme_light()
	else:
		set_theme_dark()

	update_theme()

# --- Cargar configuración completa ---
func load_user_settings_from_firestore(uid: String):
	current_user_uid = uid
	var project_id = "avatarsvsrooksproject"
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [project_id, uid]
	var headers = ["Content-Type: application/json"]

	var request := HTTPRequest.new()
	add_child(request)
	var err = request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Error al iniciar HTTPRequest (load_user_settings)")
		request.queue_free()
		return

	var signal_args: Array = await request.request_completed
	var body_bytes: PackedByteArray = signal_args[3]
	var json_text: String = body_bytes.get_string_from_utf8()
	var data: Variant = JSON.parse_string(json_text)
	request.queue_free()

	if data == null or not data.has("fields") or not data["fields"].has("settings"):
		print("⚠️ No hay configuraciones guardadas para este usuario.")
		reset_to_defaults()
		return

	var settings_map: Dictionary = data["fields"]["settings"]["mapValue"]["fields"]

	current_settings["theme"] = settings_map.get("theme", {}).get("stringValue", "Oscuro")
	current_settings["spotify_url"] = settings_map.get("spotify_url", {}).get("stringValue", "")
	current_settings["music_enabled"] = settings_map.get("music_enabled", {}).get("booleanValue", false)
	current_settings["volume_db"] = int(settings_map.get("volume_db", {}).get("integerValue", "0"))
	current_settings["resolution_index"] = int(settings_map.get("resolution_index", {}).get("integerValue", "0"))

	if settings_map.has("colors"):
		var arr: Array = []
		for color_entry in settings_map["colors"]["arrayValue"]["values"]:
			arr.append(Color(color_entry["stringValue"]))
		current_settings["colors"] = arr

	# Aplicar según el tema y colores
	if not current_settings["colors"].is_empty():
		apply_custom_colors(current_settings["colors"])
	elif current_settings["theme"] == "Claro":
		set_theme_light()
	else:
		set_theme_dark()

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), current_settings["volume_db"])
	print("✅ Configuración cargada para UID:", uid)
