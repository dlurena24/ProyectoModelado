class_name MundoOld
extends Node2D

var timer_nivel : Timer
@export var tiempo_total_nivel : float = 5


func _ready() -> void:
	#Crear temporizador
	timer_nivel = Timer.new()
	timer_nivel.one_shot = true
	timer_nivel.autostart = true
	timer_nivel.wait_time = tiempo_total_nivel
	timer_nivel.start()
	timer_nivel.timeout.connect(finalizar_nivel)
	
	
func finalizar_nivel():
	print("Nivel terminado!")
	
