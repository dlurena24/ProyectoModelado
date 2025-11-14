class_name Moneda
extends Area2D

func _ready():
	$AnimatedSprite2D.play("default")

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if Input.is_action_just_pressed("click_izquierdo"):
		print("Agrega monedas al jugador")
		Global.agregar_monedas(25) #Cantidad de monedas
		#Destruye el objeto
		queue_free()
