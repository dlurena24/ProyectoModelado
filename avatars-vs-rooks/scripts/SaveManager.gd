extends Node

const SAVE_DIR := "user://saves"
var is_loading_save: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _get_current_uid() -> String:
	var uid := GlobalSettings.current_user_uid
	return uid if uid != "" else "guest"

func _get_save_path_for_uid(uid: String) -> String:
	return "%s/%s_last.json" % [SAVE_DIR, uid]

func has_saved_game_for_current_user() -> bool:
	var path := _get_save_path_for_uid(_get_current_uid())
	return FileAccess.file_exists(path)

func delete_save_for_current_user() -> void:
	var path := _get_save_path_for_uid(_get_current_uid())
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func save_game_for_current_user(level: Node) -> bool:
	if level == null:
		push_warning("SaveManager: level es null, no se puede guardar.")
		return false

	var uid := _get_current_uid()
	var path := _get_save_path_for_uid(uid)

	var data: Dictionary = {}

	if level.has_method("get_save_data"):
		data["level_state"] = level.call("get_save_data")
	else:
		data["level_state"] = {}

	data["scene_path"] = level.get_scene_file_path()
	data["saved_at"] = int(Time.get_unix_time_from_system())
	data["global"] = {
		"monedas": Global.monedas
	}
	data["run"] = { "total_elapsed_ms": RunManager.get_total_elapsed_ms(), "current_level_index": RunManager.current_level_index }


	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: no se pudo abrir archivo de guardado: " + path)
		return false

	file.store_string(json_text)
	file.close()
	print("SaveManager: partida guardada en ", path)
	return true

func load_saved_game_for_current_user() -> void:
	var uid := _get_current_uid()
	var path := _get_save_path_for_uid(uid)
	if not FileAccess.file_exists(path):
		push_warning("SaveManager: no hay partida guardada para %s" % uid)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: no se pudo abrir guardado: " + path)
		return
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: archivo de guardado corrupto.")
		return

	var data: Dictionary = parsed
	var scene_path: String = str(data.get("scene_path",""))
	if scene_path == "":
		push_error("SaveManager: guardado sin scene_path.")
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("SaveManager: no se pudo cargar escena: " + scene_path)
		return

	is_loading_save = true

	var err := get_tree().change_scene_to_packed(packed)
	if err != OK:
		is_loading_save = false
		push_error("SaveManager: change_scene_to_packed falló con código %d" % err)
		return

	# Esperar a que la escena esté realmente cargada
	var current_level: Node = null
	for i in range(60):
		await get_tree().process_frame
		current_level = get_tree().current_scene
		if current_level != null:
			break

	if current_level == null:
		is_loading_save = false
		push_error("SaveManager: current_scene sigue null después de cargar.")
		return

	var r: Dictionary = data.get("run", {})
	RunManager.restore_from_save(int(r.get("total_elapsed_ms", 0)), int(r.get("current_level_index", 0)))

	# Restaurar datos globales (monedas)
	var g: Dictionary = data.get("global", {})
	if g.has("monedas"):
		Global.monedas = int(g.get("monedas", Global.monedas))
		Global.monedas_actualizadas.emit(Global.monedas)

	# Restaurar estado del nivel
	var level_state: Dictionary = data.get("level_state", {})
	if current_level.has_method("apply_save_data"):
		current_level.call("apply_save_data", level_state)
	else:
		push_warning("SaveManager: la escena cargada no tiene apply_save_data().")
	RunManager.resume_segment()
	is_loading_save = false
