extends Control

@onready var cantidad_monedas: Label = $PanelMonedas/HBoxContainer/Label
@onready var save_button: Button = $Control/SaveButton

func _ready() -> void:
	Global.monedas_actualizadas.connect(actualizar_monedas)
	save_button.pressed.connect(_on_save_button_pressed)
func actualizar_monedas(monedas: int):
	cantidad_monedas.text = str(monedas)
	
func _on_save_button_pressed() -> void:
	var level := get_tree().current_scene
	if level is Mundo:
		var ok := SaveManager.save_current_game(level)
		if ok:
			print("Partida guardada correctamente.")
