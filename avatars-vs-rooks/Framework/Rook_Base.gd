class_name Rook_Base
extends Node2D

@export var vida : float = 100.0
@export var vida_maxima := 100.0

@export var celda_ocupada : Vector2

@export var animacion_impacto : AnimationPlayer

func init_rook():
	vida = vida_maxima
	

func recibir_ataque(cantidad: float):
	vida -= cantidad
	
	if vida <= 0:
		queue_free()
		return
	
	animacion_impacto.play("impacto")
