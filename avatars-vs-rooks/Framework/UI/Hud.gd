extends Control

@onready var cantidad_monedas: Label = $PanelMonedas/HBoxContainer/Label
@onready var save_button: Button = $Control/SaveButton
func _ready() -> void:
	Global.monedas_actualizadas.connect(actualizar_monedas)
	if is_instance_valid(save_button):
		save_button.pressed.connect(_on_save_button_pressed)

func actualizar_monedas(monedas: int):
	cantidad_monedas.text = str(monedas)
	
func _on_save_button_pressed() -> void:
	var level := get_tree().current_scene
	if level == null:
		push_warning("HUD: no hay escena actual para guardar.")
		return
	SaveManager.save_game_for_current_user(level)
