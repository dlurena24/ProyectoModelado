extends Control

# Referencias a los botones de la interfaz
@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton


func _ready():
	# Conectamos la señal 'pressed' de cada botón a su función correspondiente.
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	await get_tree().process_frame
	GlobalSettings.update_theme()


# Esta función se ejecuta cuando se presiona el botón de Jugar
func _on_play_button_pressed():
	# Cambia a la escena principal del juego. 
	# Asegúrate de que la ruta sea correcta.
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# Esta función se ejecuta cuando se presiona el botón de Configuración
func _on_settings_button_pressed():
	# Cambia a la escena del menú de configuración.
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")


# Esta función se ejecuta cuando se presiona el botón de Salir
func _on_quit_button_pressed():
	# Cierra la aplicación del juego.
	get_tree().quit()
