class_name Cursor_Rook
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D


func actualizar_visuales(panel_rook : PanelRook):
	if panel_rook == null:
		sprite.texture = null
		return
	sprite.texture = panel_rook.textura
	
func establecer_celda_valida(valor : bool):
	if valor:
		sprite.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		sprite.self_modulate = Color(0.857, 0.058, 0.0, 0.5)
