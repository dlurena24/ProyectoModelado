extends Control

@onready var cantidad_monedas: Label = $HBoxContainer/Label

func _ready() -> void:
	Global.monedas_actualizadas.connect(actualizar_monedas)

func actualizar_monedas(monedas: int):
	cantidad_monedas.text = str(monedas)
	
