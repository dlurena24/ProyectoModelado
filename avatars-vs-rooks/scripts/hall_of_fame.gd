extends Control

@onready var title_label: Label = $Margin/VBox/Title
@onready var tree: Tree = $Margin/VBox/ScoresTree
@onready var refresh_btn: Button = $Margin/VBox/Buttons/RefreshButton
@onready var back_btn: Button = $Margin/VBox/Buttons/BackButton

func _ready() -> void:
	title_label.text = "Salón de la Fama"

	# Configurar columnas (Godot 4)
	tree.columns = 3
	tree.set_column_title(0, "#")
	tree.set_column_title(1, "Usuario")
	tree.set_column_title(2, "Tiempo")
	tree.set_column_expand(0, false)
	tree.set_column_custom_minimum_width(0, 40) # ← antes: set_column_min_width (G3)
	tree.set_column_titles_visible(true)
	tree.set_hide_root(true)

	refresh_btn.pressed.connect(_load_runs)
	back_btn.pressed.connect(_go_back)

	await _load_runs()
	GlobalSettings.update_theme()

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _load_runs() -> void:
	tree.clear()
	var root := tree.create_item()

	# Cargar del backend (ordenado por time_ms asc)
	var rows: Array = await FirestoreService.get_top_runs(100)

	# Si aún no hay datos, usar falsos
	if rows.is_empty():
		rows = _fake_rows()

	var rank := 1
	for r in rows:
		var it := tree.create_item(root)
		it.set_text(0, str(rank))

		var uname: String = str(r.get("username", "")).strip_edges()
		if uname == "" or uname == "<null>":
			uname = "(sin nombre)"
		it.set_text(1, uname)

		var ms: int = int(r.get("time_ms", 0))
		it.set_text(2, _format_ms(ms))

		rank += 1

# ---- Utilidades ----

static func _format_ms(ms: int) -> String:
	var total_sec: int = ms / 1000
	var minutes: int = total_sec / 60
	var seconds: int = total_sec % 60
	var millis: int = ms % 1000
	return "%02d:%02d.%03d" % [minutes, seconds, millis]

static func _fake_rows() -> Array:
	return [
		{"username": "Luna",     "time_ms":  84532},
		{"username": "Sol",      "time_ms":  92310},
		{"username": "Orion",    "time_ms": 101225},
		{"username": "Valkyria", "time_ms": 110877},
		{"username": "Atlas",    "time_ms": 120004}
	]
