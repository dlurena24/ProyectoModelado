extends Node2D

@export var wait_seconds: float = 3.0
@onready var t: Timer = $Timer

func _ready() -> void:
	t.one_shot = true
	t.wait_time = wait_seconds
	t.timeout.connect(_go_next)
	t.start()

func _go_next() -> void:

		# fallback por si algo salió raro
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	return
