class_name Mundo
extends Node2D

@onready var celdas: Node2D = $Celdas
@onready var cursor_rook: Node2D = $Cursor_Rook
@onready var rooks: Node2D = $Rooks

@onready var timer_avatar_spawn: Timer = $TimerAvatarEscudero
@onready var timer_monedas: Timer = $TimerMonedas
@onready var timer_nivel: Timer = $TimerNivel

@export_range(1, 3, 1) var level_number: int = 1
@export_file("*.tscn") var next_level_scene: String = ""


# Avatars
@export var escudero : PackedScene
@export var flechador : PackedScene
@export var lenador : PackedScene
@export var canival : PackedScene

@export var moneda : PackedScene

var enemigos_totales : float = 10
@onready var enemigos_muertos : int = 0
@export var porcentaje_aumento : float 

@onready var marcadoresAvatars = [
	$Lineas/Marker0,
	$Lineas/Marker1,
	$Lineas/Marker2,
	$Lineas/Marker3,
	$Lineas/Marker4
]

@onready var marcadoresMonedas = [
	$MarMonedas/Marker2D,
	$MarMonedas/Marker2D2, 
	$MarMonedas/Marker2D3, 
	$MarMonedas/Marker2D4,
	$MarMonedas/Marker2D5, 
	$MarMonedas/Marker2D6, 
	$MarMonedas/Marker2D7
]

var avatars = ["flechador", "escudero", "lenador", "canival"]
var weights = [40, 30, 20, 10]  

func _ready():
	# Establecer variables del GameManager
	GameManager.nivel_actual = self
	GameManager.cursor_rook = $Cursor_Rook
	enemigos_totales = enemigos_totales + enemigos_totales * porcentaje_aumento
	print("Enemigos totales: ", enemigos_totales)
	# Crear celdas
	crear_celdas()
	celdas.visible = false
	
	timer_nivel.start()
	#timer_nivel.timeout.connect(ganar_nivel)
	
	timer_avatar_spawn.start()
	timer_avatar_spawn.timeout.connect(spawnear_avatar)
	
	timer_monedas.start()
	timer_monedas.timeout.connect(spawnear_moneda)
	randomize()
	
	if level_number == 1 and not RunManager.is_running:
		RunManager.start_new_run()
	else:
		# Si venís de continuar/cambio de escena, aseguramos que el segmento corra.
		RunManager.resume_segment()

	RunManager.current_level_index = level_number - 1
	
func mostrar_celdas(valor : bool):
	celdas.visible = valor

func crear_celdas():
	var celda_paquete := load("res://Framework/Clases/celda_rook.tscn")
	for x in range(0, 5):
		for y in range(0, 9):
			var nueva_celda = celda_paquete.instantiate()
			celdas.add_child(nueva_celda)
			nueva_celda.position = Vector2(48.5, 48) + (Vector2(x,y) * Vector2(97, 96))
			nueva_celda.posicion_celda = Vector2i(x,y)
			

# Avatars

func weighted_choice(options: Array, weights: Array):
	var total := 0
	for w in weights:
		total += w
	
	var r := randi() % total
	var cumulative := 0
	
	for i in range(options.size()):
		cumulative += weights[i]
		if r < cumulative:
			return options[i]
			
func spawnear_escudero():
	var escudero_a_colocar = escudero.instantiate()
	get_tree().current_scene.add_child(escudero_a_colocar)
	var marker_pos = randi_range(0, 4)
	var marcador = marcadoresAvatars[marker_pos]
	escudero_a_colocar.global_position = marcador.global_position
	
func spawnear_flechador():
	var flechador_a_colocar = flechador.instantiate()
	get_tree().current_scene.add_child(flechador_a_colocar)
	var marker_pos = randi_range(0, 4)
	var marcador = marcadoresAvatars[marker_pos]
	flechador_a_colocar.global_position = marcador.global_position
	
func spawnear_canival():
	var canival_a_colocar = canival.instantiate()
	get_tree().current_scene.add_child(canival_a_colocar)
	var marker_pos = randi_range(0, 4)
	var marcador = marcadoresAvatars[marker_pos]
	canival_a_colocar.global_position = marcador.global_position
	
func spawnear_lenador():
	var lenador_a_colocar = lenador.instantiate()
	get_tree().current_scene.add_child(lenador_a_colocar)
	var marker_pos = randi_range(0, 4)
	var marcador = marcadoresAvatars[marker_pos]
	lenador_a_colocar.global_position = marcador.global_position
	
func spawnear_avatar():
	var chosen_room = weighted_choice(avatars, weights)

	match chosen_room:
		"flechador":
			spawnear_flechador()
		"escudero":
			spawnear_escudero()
		"lenador":
			spawnear_lenador()
		"canival":
			spawnear_canival()

func spawnear_moneda():
	var moneda_a_colocar = moneda.instantiate()
	get_tree().current_scene.add_child(moneda_a_colocar)
	var marker_pos = randi_range(0, 6)
	var marcador = marcadoresMonedas[marker_pos]
	moneda_a_colocar.global_position = marcador.global_position
	
func ganar_nivel():
	print("Nivel terminado!")

	# NO contar transiciones / pantalla victoria
	RunManager.pause_segment()

	# Si hay siguiente nivel → pantalla intermedia 3s
	if next_level_scene != "":
		RunManager.pending_next_scene_path = next_level_scene
		get_tree().change_scene_to_file("res://Framework/LevelVictory.tscn")
		return

	# Si NO hay siguiente nivel, este es el NIVEL 3 (final)
	var total_ms: int = RunManager.get_total_elapsed_ms()

	var uid := GlobalSettings.current_user_uid
	var role := str(GlobalSettings.user_profile.get("role", "user"))
	if uid != "" and role != "admin":
		var uname := str(GlobalSettings.user_profile.get("username", "")).strip_edges()
		if uname == "" or uname == "<null>":
			uname = uid
		var ok := await FirestoreService.submit_best_run(uid, uname, total_ms)
		if not ok:
			push_warning("No se pudo registrar el tiempo en el salón de la fama.")

	
	SaveManager.delete_save_for_current_user()

	RunManager.end_run()
	get_tree().change_scene_to_file("res://Framework/GameWon.tscn")


func sumar_enemigo_muerto():
	enemigos_muertos = enemigos_muertos + 1
	print(enemigos_muertos)
	if enemigos_muertos >= enemigos_totales:
		ganar_nivel()
	

#  SISTEMA DE GUARDADO

func _vec2_to_array(v: Vector2) -> Array:
	return [v.x, v.y]

func _array_to_vec2(a: Array) -> Vector2:
	if a.size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO

func _vec2i_to_array(v: Vector2i) -> Array:
	return [v.x, v.y]

func _array_to_vec2i(a: Array) -> Vector2i:
	if a.size() >= 2:
		return Vector2i(int(a[0]), int(a[1]))
	return Vector2i.ZERO


func _save_rooks() -> Array:
	var result: Array = []

	for grid_pos in GameManager.rooks_colocados.keys():
		var rook: Node2D = GameManager.rooks_colocados[grid_pos]
		if not is_instance_valid(rook):
			continue

		var entry: Dictionary = {
			"scene_path": rook.get_scene_file_path(),
			"grid_pos": _vec2i_to_array(grid_pos),
			"global_pos": _vec2_to_array(rook.global_position),
		}

		if rook is Rook_Base:
			entry["vida"] = rook.vida
			entry["vida_maxima"] = rook.vida_maxima

		result.append(entry)

	return result


func _load_rooks(data: Array) -> void:
	# Borrar rooks actuales
	for rook in GameManager.rooks_colocados.values():
		if is_instance_valid(rook):
			rook.queue_free()
	GameManager.rooks_colocados.clear()

	for item in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item

		var scene_path: String = str(d.get("scene_path", ""))
		if scene_path == "":
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			continue

		var rook := packed.instantiate()
		rooks.add_child(rook)

		var grid_pos := _array_to_vec2i(d.get("grid_pos", []))
		rook.global_position = _array_to_vec2(d.get("global_pos", []))

		GameManager.rooks_colocados[grid_pos] = rook

		# IMPORTANTE: aplicar vida y reiniciar timer después del _ready()
		call_deferred("_apply_loaded_rook_state", rook, d)

func _apply_loaded_rook_state(rook: Node, d: Dictionary) -> void:
	if not is_instance_valid(rook):
		return

	# Restaurar vida (después de init_rook() de _ready)
	if rook is Rook_Base:
		var r := rook as Rook_Base
		r.vida_maxima = float(d.get("vida_maxima", r.vida_maxima))
		r.vida = float(d.get("vida", r.vida))

	# “Kick” al temporizador de disparo (esto arregla el “no dispara hasta que pase algo”)
	var t := rook.get_node_or_null("Timer") as Timer
	if t:
		t.stop()
		t.start()


func _get_root_scene() -> Node:
	return get_tree().current_scene


func _save_avatars() -> Array:
	var result: Array = []
	var root := _get_root_scene()
	if root == null:
		return result

	for child in root.get_children():
		if child is Avatar:
			var entry: Dictionary = {
				"scene_path": child.get_scene_file_path(),
				"global_pos": _vec2_to_array(child.global_position),
				"salud_actual": child.salud_actual,
				"estado_actual": child.estado_actual,
			}
			result.append(entry)

	return result


func _load_avatars(data: Array) -> void:
	var root := _get_root_scene()
	if root == null:
		return

	# Borrar avatars actuales
	for child in root.get_children():
		if child is Avatar:
			child.queue_free()

	for item in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item

		var scene_path: String = str(d.get("scene_path", ""))
		if scene_path == "":
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			continue

		var avatar := packed.instantiate()
		root.add_child(avatar)

		avatar.global_position = _array_to_vec2(d.get("global_pos", []))

		
		call_deferred("_apply_loaded_avatar_state", avatar, d)

func _apply_loaded_avatar_state(avatar: Node, d: Dictionary) -> void:
	if not is_instance_valid(avatar) or not (avatar is Avatar):
		return

	var a := avatar as Avatar

	# Restaurar salud (después de que _ready() la resetea)
	if d.has("salud_actual"):
		a.salud_actual = float(d["salud_actual"])

	# Restaurar estado y FORZAR que reproduzca animación
	a.estado_actual = int(d.get("estado_actual", Avatar.CAMINAR))
	a.estado_previo = -999  # fuerza el play en el próximo _physics_process

	# “kick” inmediato
	if is_instance_valid(a.animacion):
		if a.estado_actual == Avatar.ATACAR:
			a.animacion.play("atacar")
		else:
			a.animacion.play("caminar")


func _save_monedas() -> Array:
	var result: Array = []
	var root := _get_root_scene()
	if root == null:
		return result

	for child in root.get_children():
		if child is Moneda:
			var entry: Dictionary = {
				"scene_path": child.get_scene_file_path(),
				"global_pos": _vec2_to_array(child.global_position),
			}
			result.append(entry)

	return result


func _load_monedas(data: Array) -> void:
	var root := _get_root_scene()
	if root == null:
		return

	# Borrar monedas actuales
	for child in root.get_children():
		if child is Moneda:
			child.queue_free()

	for item in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = item

		var scene_path: String = str(d.get("scene_path", ""))
		if scene_path == "":
			continue

		var packed: PackedScene = load(scene_path)
		if packed == null:
			continue

		var moneda := packed.instantiate()
		root.add_child(moneda)

		var global_pos_arr :Variant= d.get("global_pos", [])
		moneda.global_position = _array_to_vec2(global_pos_arr)


# --------- API que usa SaveManager ---------

func get_save_data() -> Dictionary:
	var state: Dictionary = {}

	# Datos generales del nivel
	state["level_number"] = level_number
	state["enemigos_totales"] = enemigos_totales
	state["enemigos_muertos"] = enemigos_muertos

	# Torres, enemigos y monedas
	state["rooks"] = _save_rooks()
	state["avatars"] = _save_avatars()
	state["monedas"] = _save_monedas()

	return state


func apply_save_data(state: Dictionary) -> void:
	# Restaurar datos básicos del nivel
	level_number = int(state.get("level_number", level_number))
	enemigos_totales = float(state.get("enemigos_totales", enemigos_totales))
	enemigos_muertos = int(state.get("enemigos_muertos", enemigos_muertos))

	# Reconstruir objetos dinámicos
	_load_rooks(state.get("rooks", []))
	_load_avatars(state.get("avatars", []))
	_load_monedas(state.get("monedas", []))
