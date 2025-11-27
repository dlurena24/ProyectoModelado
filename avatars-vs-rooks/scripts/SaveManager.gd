extends Node

const SAVE_DIR := "user://saves"

func _get_save_path_for_uid(uid: String) -> String:
	var safe_uid := uid
	if safe_uid.is_empty():
		safe_uid = "guest"
	return "%s/%s_last.json" % [SAVE_DIR, safe_uid]

func has_save_for_current_user() -> bool:
	var uid := GlobalSettings.current_user_uid
	if uid.is_empty():
		uid = "guest"
	var path := _get_save_path_for_uid(uid)
	return FileAccess.file_exists(path)

func save_current_game(level: Node) -> bool:
	if level == null:
		push_error("SaveManager.save_current_game: level es null")
		return false

	var data: Dictionary = {}

	# Escena actual (Godot 4)
	data["scene_path"] = level.get_scene_file_path()

	# Estado específico del nivel
	if level.has_method("get_save_data"):
		data["level_state"] = level.call("get_save_data")
	else:
		data["level_state"] = {}

	# Estado global mínimo (puedes agregar más)
	data["global"] = {
		"monedas": Global.monedas
	}

	# Usuario actual
	data["uid"] = GlobalSettings.current_user_uid
	data["username"] = GlobalSettings.user_profile.get("username", "")
	data["saved_at"] = Time.get_unix_time_from_system()

	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path := _get_save_path_for_uid(data["uid"])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo abrir archivo de guardado: " + path)
		return false

	file.store_string(JSON.stringify(data))
	file.close()
	print("Partida guardada en: ", path)
	return true

func load_saved_game_for_current_user() -> void:
	var uid := GlobalSettings.current_user_uid
	if uid.is_empty():
		uid = "guest"

	var path := _get_save_path_for_uid(uid)
	if not FileAccess.file_exists(path):
		push_warning("No hay partida guardada para este usuario.")
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir guardado: " + path)
		return

	var text := file.get_as_text()
	file.close()

	var parsed :Variant= JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Archivo de guardado corrupto.")
		return

	var data: Dictionary = parsed
	var scene_path: String = data.get("scene_path", "")
	if scene_path == "":
		push_error("Guardado sin scene_path.")
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("No se pudo cargar escena: " + scene_path)
		return

	# Cambiar escena y validar error
	var err := get_tree().change_scene_to_packed(packed)
	if err != OK:
		push_error("change_scene_to_packed falló. Error code: %s" % str(err))
		return

	# Esperar hasta que la escena exista (evita current_scene null)
	var current_level: Node = null
	for i in range(30): # ~30 frames como máximo (súper seguro)
		await get_tree().process_frame
		current_level = get_tree().current_scene
		if current_level != null:
			break

	if current_level == null:
		push_error("No se pudo obtener current_scene después de cargar. (sigue null)")
		return

	# Restaurar estado global
	var g: Dictionary = data.get("global", {})
	Global.monedas = int(g.get("monedas", Global.monedas))
	Global.monedas_actualizadas.emit(Global.monedas)

	# Restaurar estado del nivel
	var level_state: Dictionary = data.get("level_state", {})
	if current_level.has_method("apply_save_data"):
		current_level.call("apply_save_data", level_state)
	else:
		push_warning("La escena cargada no tiene apply_save_data().")
