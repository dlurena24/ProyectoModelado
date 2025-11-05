class_name Bala
extends Area2D

var speed := 100.0

func _ready() -> void:
	$AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	position.y += speed * delta 

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	pass
	#if body is Avatar:
		## Animacion de impacto###
		## Aplicar daño al avatar
		#queue_free()
