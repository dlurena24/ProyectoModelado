class_name PanelRook
extends Panel

@export var textura : Texture2D
@export var tiempo_de_recuperacion : float = 2.0
@export var precio_monedas : int = 5
@export var rool_a_colocar : PackedScene

func _ready():
	# Parametros iniciales
	$TextureRect.texture = textura
	$Label.text = str(precio_monedas)
	# Configurar temporizador
	$Timer.wait_time = tiempo_de_recuperacion
	$Timer.one_shot = true
	
func _on_gui_input(event:InputEvent):
	if Input.is_action_just_pressed("click_izquierdo"):
		GameManager.rook_seleccionado(self)
