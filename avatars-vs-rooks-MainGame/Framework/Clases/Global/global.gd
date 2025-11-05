extends Node
signal monedas_actualizadas(cantidad)

var monedas : int = 500

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	monedas_actualizadas.emit(monedas)

func agregar_monedas(cantidad):
	monedas += cantidad
	monedas_actualizadas.emit(monedas)
	
func quitar_monedas(cantidad):
	monedas -= cantidad
	monedas_actualizadas.emit(monedas)
