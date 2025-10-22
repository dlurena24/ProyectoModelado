class_name Nivel
extends Node2D

@onready var celdas: Node2D = $Celdas
@onready var cursor_rook: Node2D = $Cursor_Rook
@onready var rooks: Node2D = $Rooks


func _ready():
	# Establecer variables del GameManager
	GameManager.nivel_actual = self
	GameManager.cursor_rook = $Cursor_Rook
	
	# Crear celdas
	crear_celdas()
	celdas.visible = false
	
func mostrar_celdas(valor : bool):
	celdas.visible = valor

func crear_celdas():
	var celda_paquete := load("res://Framework/Clases/celda_rook.tscn")
	for x in range(0, 5):
		for y in range(0, 9):
			var nueva_celda = celda_paquete.instantiate()
			celdas.add_child(nueva_celda)
			nueva_celda.position = Vector2(48.5, 48) + (Vector2(x,y) * Vector2(97, 96))
			
	
