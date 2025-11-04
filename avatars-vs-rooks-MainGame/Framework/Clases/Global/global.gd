extends Node
signal monedas_actualizadas(cantidad)

var monedas : int = 0

func agregar_monedas(cantidad):
	monedas += cantidad
	monedas_actualizadas.emit(monedas)
	
func quitar_monedas(cantidad):
	monedas -= cantidad
	monedas_actualizadas.emit(monedas)
