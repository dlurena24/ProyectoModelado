class_name Rook_Test
extends Rook_Base

@export var daño_disparo : int = 25
@export var tiempo_por_disparo : float = 1.0

# Disparo
var avatar_al_alcance := true
@export var bala_instancia : PackedScene  

@onready var timer: Timer = $Timer
@onready var marker_2d: Marker2D = $Marker2D

# Called when the node enters the scene tree for the first time.
func _ready():
	init_rook()
	timer.wait_time = tiempo_por_disparo
	timer.timeout.connect(disparar)
	
	# Test
	timer.start()
	
func disparar():
	#print("DISPARAR Rook_Test")
	# Revisa si puede disparar
	if avatar_al_alcance:
		spawnear_bala()
		

func spawnear_bala():
	var bala = bala_instancia.instantiate()
	get_tree().current_scene.add_child(bala)
	bala.daño = daño_disparo
	bala.global_position = marker_2d.global_position
