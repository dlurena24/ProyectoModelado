class_name Rook_Test
extends Rook_Base

@export var daño_disparo : float = 25
@export var tiempo_por_disparo : float = 1.0

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	init_rook()
	timer.wait_time = tiempo_por_disparo
	timer.timeout.connect(disparar)
	
func disparar():
	print("DISPARAR Rook_Test")
