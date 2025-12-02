class_name Celda_Rook
extends Area2D

var posicion_celda : Vector2i

func _on_mouse_entered():
	GameManager.actualizar_celda_actual(posicion_celda, self)
	
func _on_mouse_exited():
	pass # Replace with function body.

func _on_input_event(viewport, event, shape_idx):
	if Input.is_action_just_pressed("click_izquierdo"):
		GameManager.intentar_colocar_rook()
	else:
		#print("else")
		pass
