class_name Mundo
extends Node2D

@onready var celdas: Node2D = $Celdas
@onready var cursor_rook: Node2D = $Cursor_Rook
@onready var rooks: Node2D = $Rooks

@onready var timer_avatar_spawn: Timer = $TimerAvatarEscudero
@onready var timer_monedas: Timer = $TimerMonedas
@onready var timer_nivel: Timer = $TimerNivel


# Avatars
@export var escudero : PackedScene
@export var flechador : PackedScene
@export var lenador : PackedScene
@export var canival : PackedScene

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
	
	timer_avatar_spawn.start()
	timer_avatar_spawn.timeout.connect(spawnear_avatar)
	
	timer_monedas.start()
	timer_monedas.timeout.connect(spawnear_moneda)
	randomize()
	
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
			

var avatars = ["flechador", "escudero", "lenador", "canival"]
var weights = [40, 30, 20, 10]  

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
	get_tree().change_scene_to_file("res://Framework/GameWon.tscn")
