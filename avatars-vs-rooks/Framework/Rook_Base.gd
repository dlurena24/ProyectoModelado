class_name Rook_Base
extends Node2D

@export var vida : float = 100.0
@export var vida_maxima := 100.0

@export var celda_ocupada : Vector2

func init_rook():
	vida = vida_maxima
