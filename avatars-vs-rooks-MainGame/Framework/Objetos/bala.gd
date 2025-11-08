class_name Bala
extends Area2D

var speed := 100.0

func _ready() -> void:
	$AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	position.y += speed * delta 

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var target_avatar = area.get_parent()
	if target_avatar is Avatar:
			# Animacion de impacto###
			# Aplicar daño al avatar
			target_avatar.recibir_ataque(25)
			
			# Elimina bala
			queue_free()
