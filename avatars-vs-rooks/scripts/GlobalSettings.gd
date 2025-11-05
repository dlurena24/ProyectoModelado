extends Node

signal user_profile_changed(profile: Dictionary)

const DEFAULT_SETTINGS := {
	"theme": "Claro",
	"volume_db": 0,
	"music_enabled": false,
	"spotify_url": "",
	"colors": [],        # Personalizado: [bg, text]
	"resolution_index": 0
}

var background_color: Color = Color.BLACK
var text_color: Color = Color.WHITE

var current_user_uid: String = ""
var current_settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var user_profile: Dictionary = {}  # { uid, role, username, name, profile_picture_url, profile_picture_path }

func set_current_user(uid: String) -> void:
	current_user_uid = uid

# ---------- helpers ----------
func _nz_str(v: Variant) -> String:
	if v == null:
		return ""
	var s := str(v)
	return "" if s == "<null>" else s

func _auto_contrast(bg: Color) -> Color:
	var luma: float = 0.2126 * bg.r + 0.7152 * bg.g + 0.0722 * bg.b
	return Color(0,0,0) if luma > 0.6 else Color(1,1,1)

# ---------- Temas ----------
func set_theme_light() -> void:
	current_settings["theme"] = "Claro"
	current_settings["colors"] = []
	background_color = Color(0.95, 0.95, 0.95)
	text_color = Color(0.10, 0.10, 0.10)
	update_theme()

func set_theme_dark() -> void:
	current_settings["theme"] = "Oscuro"
	current_settings["colors"] = []
	background_color = Color(0.08, 0.08, 0.08)
	text_color = Color(1, 1, 1)
	update_theme()

# Personalizado usa SOLO Color1 (bg) y Color2 (text)
func apply_palette_or_theme(palette: Array, theme_name: String) -> void:
	current_settings["theme"] = theme_name

	if theme_name == "Personalizado":
		var bg: Color = Color(0.1, 0.1, 0.1)
		var txt: Color = Color(1, 1, 1)

		if palette.size() >= 1:
			var p0: Variant = palette[0]
			if p0 is Color:
				bg = p0
			else:
				bg = Color(str(p0))

		if palette.size() >= 2:
			var p1: Variant = palette[1]
			if p1 is Color:
				txt = p1
			else:
				txt = Color(str(p1))
		else:
			# Si no hay Color2, calculamos un texto con buen contraste
			txt = _auto_contrast(bg)

		current_settings["colors"] = [bg, txt]
		background_color = bg
		text_color = txt
	else:
		# Claro/Oscuro: ignorar paleta
		current_settings["colors"] = []
		if theme_name == "Claro":
			background_color = Color(0.95, 0.95, 0.95)
			text_color = Color(0.10, 0.10, 0.10)
		else:
			background_color = Color(0.08, 0.08, 0.08)
			text_color = Color(1, 1, 1)

	update_theme()
	
	
func update_theme() -> void:
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", background_color)
	var root: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	if root != null:
		_apply_theme_recursive(root)

func _apply_theme_recursive(node: Node) -> void:
	if node is Label:
		(node as Label).add_theme_color_override("font_color", text_color)
	elif node is Button:
		_set_colors(node as Control, [
			"font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"
		], text_color)
	elif node is LineEdit:
		var le := node as LineEdit
		le.add_theme_color_override("font_color", text_color)
		le.add_theme_color_override("caret_color", text_color)
		le.add_theme_color_override("font_placeholder_color", text_color.lerp(background_color, 0.5))
	elif node is OptionButton:
		_set_colors(node as Control, [
			"font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"
		], text_color)
		(node as OptionButton).add_theme_color_override("arrow_color", text_color)
	elif (node is CheckBox) or (node is CheckButton):
		_set_colors(node as Control, [
			"font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"
		], text_color)
	elif node is RichTextLabel:
		(node as RichTextLabel).add_theme_color_override("default_color", text_color)

	for child in node.get_children():
		if child is Node:
			_apply_theme_recursive(child)

func _set_colors(c: Control, keys: Array, col: Color) -> void:
	for k in keys:
		c.add_theme_color_override(k, col)

# ---------- Firestore: SETTINGS ----------
func save_user_theme_to_firestore() -> void:
	if current_user_uid == "":
		push_warning("No hay UID para guardar tema.")
		return

	var colors_html: Array = []
	for c in current_settings.get("colors", []):
		var col: Color = c if c is Color else Color(str(c))
		colors_html.append(col.to_html())

	var data := {
		"settings": {
			"theme": str(current_settings.get("theme","Oscuro")),
			"spotify_url": str(current_settings.get("spotify_url","")),
			"music_enabled": bool(current_settings.get("music_enabled", false)),
			"volume_db": int(current_settings.get("volume_db", 0)),
			"resolution_index": int(current_settings.get("resolution_index", 0)),
			"colors": colors_html
		},
		"theme_background": background_color.to_html(),
		"theme_text": text_color.to_html()
	}
	var ok: bool = await FirestoreService.upsert_user(current_user_uid, data) # ← merge con updateMask
	if not ok:
		push_error("No se pudo guardar el tema en Firestore.")
	update_theme()

func load_user_settings_from_firestore(uid: String) -> void:
	current_user_uid = uid
	var s: Dictionary = await FirestoreService.get_user_settings(uid)
	if s.is_empty():
		set_theme_dark()
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
		return

	current_settings["theme"] = str(s.get("theme","Oscuro"))
	current_settings["spotify_url"] = str(s.get("spotify_url",""))
	current_settings["music_enabled"] = bool(s.get("music_enabled", false))
	current_settings["volume_db"] = int(s.get("volume_db", 0))
	current_settings["resolution_index"] = int(s.get("resolution_index", 0))

	# reconstruir paleta (máx 2)
	current_settings["colors"] = []
	if s.has("colors") and s["colors"] is Array:
		for entry in s["colors"]:
			if current_settings["colors"].size() >= 2:
				break
			var col: Color = entry if entry is Color else Color(str(entry))
			current_settings["colors"].append(col)

	var th := str(current_settings["theme"])
	if th == "Claro":
		set_theme_light()
	elif th == "Personalizado" and not current_settings["colors"].is_empty():
		apply_palette_or_theme(current_settings["colors"], "Personalizado")
	else:
		set_theme_dark()

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), float(current_settings["volume_db"]))

# ---------- Firestore: PERFIL ----------
func load_user_profile(uid: String) -> void:
	var p: Dictionary = await FirestoreService.get_user_profile(uid)

	user_profile = {
		"uid": uid,
		"role": _nz_str(p.get("role","user")),
		"username": _nz_str(p.get("username","")),
		"name": _nz_str(p.get("name","")),
		"profile_picture_url": _nz_str(p.get("profile_picture_url","")),
		"profile_picture_path": _nz_str(p.get("profile_picture_path",""))
	}

	emit_signal("user_profile_changed", user_profile)
