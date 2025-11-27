class_name Mundo
extends Node2D

#Tiempo
var run_start_ms: int = 0

@onready var celdas: Node2D = $Celdas
@onready var cursor_rook: Node2D = $Cursor_Rook
@onready var rooks: Node2D = $Rooks

@onready var timer_avatar_escudero: Timer = $TimerAvatarEscudero
@onready var timer_monedas: Timer = $TimerMonedas
@onready var timer_nivel: Timer = $TimerNivel


# Avatars
@export var escudero : PackedScene

@export var moneda : PackedScene

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

func _ready():
	# Establecer variables del GameManager
	GameManager.nivel_actual = self
	GameManager.cursor_rook = $Cursor_Rook
	
	# Crear celdas
	crear_celdas()
	celdas.visible = false
	
	timer_nivel.start()
	timer_nivel.timeout.connect(ganar_nivel)
	
	timer_avatar_escudero.start()
	timer_avatar_escudero.timeout.connect(spawnear_escudero)
	
	timer_monedas.start()
	timer_monedas.timeout.connect(spawnear_moneda)
	randomize()
	#Calcular tiempo
	run_start_ms = Time.get_ticks_msec()
	
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
			
	
func spawnear_escudero():
	var escudero_a_colocar = escudero.instantiate()
	get_tree().current_scene.add_child(escudero_a_colocar)
	var marker_pos = randi_range(0, 4)
	var marcador = marcadoresAvatars[marker_pos]
	escudero_a_colocar.global_position = marcador.global_position
	
func spawnear_moneda():
	var moneda_a_colocar = moneda.instantiate()
	get_tree().current_scene.add_child(moneda_a_colocar)
	var marker_pos = randi_range(0, 6)
	var marcador = marcadoresMonedas[marker_pos]
	moneda_a_colocar.global_position = marcador.global_position
	
func ganar_nivel() -> void:
	print("Nivel terminado!")

	var elapsed_ms := Time.get_ticks_msec() - run_start_ms
	if elapsed_ms < 0:
		elapsed_ms = 0

	if GlobalSettings.current_user_uid != "":
		var uname: String = GlobalSettings.user_profile.get("username", "")
		if uname == "" or uname == "<null>":
			uname = "(sin nombre)"
		var ok := await FirestoreService.submit_run(
			GlobalSettings.current_user_uid,
			uname,
			elapsed_ms
		)
		if not ok:
			push_warning("No se pudo enviar el tiempo al salón de la fama.")

	get_tree().change_scene_to_file("res://Framework/GameWon.tscn")
	
func get_save_data() -> Dictionary:
	var data: Dictionary = {}

	# Timers (para que continúe con los mismos tiempos restantes)
	data["timer_nivel_left"] = timer_nivel.time_left
	data["timer_avatar_escudero_left"] = timer_avatar_escudero.time_left
	data["timer_monedas_left"] = timer_monedas.time_left

	# Rooks colocados
	var rooks_data: Array = []
	for child in rooks.get_children():
		if child is Node2D:
			var entry := {
				"scene": child.get_scene_file_path(),
				"x": child.global_position.x,
				"y": child.global_position.y
			}
			rooks_data.append(entry)
	data["rooks"] = rooks_data

	# Tiempo de inicio (para el cálculo del tiempo total al ganar,
	# incluso si reanuda desde un guardado)
	data["run_start_ms"] = run_start_ms

	return data

func apply_save_data(data: Dictionary) -> void:
	# Restaurar tiempo de inicio
	run_start_ms = int(data.get("run_start_ms", Time.get_ticks_msec()))

	# Timers
	var left_nivel := float(data.get("timer_nivel_left", timer_nivel.wait_time))
	var left_avatar := float(data.get("timer_avatar_escudero_left", timer_avatar_escudero.wait_time))
	var left_monedas := float(data.get("timer_monedas_left", timer_monedas.wait_time))

	timer_nivel.stop()
	timer_avatar_escudero.stop()
	timer_monedas.stop()

	timer_nivel.start(left_nivel)
	timer_avatar_escudero.start(left_avatar)
	timer_monedas.start(left_monedas)

	# Limpiar rooks actuales
	for child in rooks.get_children():
		child.queue_free()

	# Volver a instanciar rooks
	var rooks_data: Array = data.get("rooks", [])
	for r in rooks_data:
		var scene_path: String = r.get("scene", "")
		if scene_path == "":
			continue
		var ps: PackedScene = load(scene_path)
		if ps == null:
			continue
		var rook := ps.instantiate()
		rooks.add_child(rook)
		rook.global_position = Vector2(r.get("x", 0.0), r.get("y", 0.0))
