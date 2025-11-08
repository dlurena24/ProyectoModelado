extends Mundo

@onready var celdas: Node2D = $Celdas
@onready var cursor_rook: Node2D = $Cursor_Rook
@onready var rooks: Node2D = $Rooks

@onready var timer_avatar_escudero: Timer = $TimerAvatarEscudero

# Avatars
@export var escudero : PackedScene

# Marcadores
#@onready var marker_0: Marker2D = $Lineas/Marker0
#@onready var marker_1: Marker2D = $Lineas/Marker1
#@onready var marker_2: Marker2D = $Lineas/Marker2
#@onready var marker_3: Marker2D = $Lineas/Marker3
#@onready var marker_4: Marker2D = $Lineas/Marker4

#var markers := [marker_0, marker_1, marker_2, marker_3, marker_4]

@onready var marcadores = [
	$Lineas/Marker0,
	$Lineas/Marker1,
	$Lineas/Marker2,
	$Lineas/Marker3,
	$Lineas/Marker4
]


func _ready():
	# Establecer variables del GameManager
	GameManager.nivel_actual = self
	GameManager.cursor_rook = $Cursor_Rook
	
	# Crear celdas
	crear_celdas()
	celdas.visible = false
	
	#Inicializar clase
	inicializar_mundo()
	
	timer_avatar_escudero.start()
	timer_avatar_escudero.timeout.connect(spawnear_escudero)
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
			
	
func spawnear_escudero():
	var escudero_a_colocar = escudero.instantiate()
	get_tree().current_scene.add_child(escudero_a_colocar)
	var marker_pos = randi_range(0, 4)
	var marcador = marcadores[marker_pos]
	escudero_a_colocar.global_position = marcador.global_position
