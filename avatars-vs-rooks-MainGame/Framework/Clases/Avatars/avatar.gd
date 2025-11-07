extends CharacterBody2D

enum {CAMINAR, ATACAR}

var direccion := -1
var estado_actual = CAMINAR
var estado_previo

@export var ataque : float = 20
@export var tiempo_de_ataque : float = 2.0
@export var velocidad : float = 25.0


var rook_a_atacar : Rook_Base

@onready var animacion: AnimationPlayer = $AnimationPlayer
@onready var atacar_rook_timer: Timer = $AtacarRookTimer


func _physics_process(delta: float) -> void:
	if estado_actual != estado_previo:
		match estado_actual:
			CAMINAR:
				animacion.play("caminar")
			ATACAR:
				animacion.play("atacar")
		estado_previo = estado_actual
		
	if estado_actual == CAMINAR:
		velocity.y = velocidad * direccion
	else:
		velocity.y = 0
	
	move_and_slide()

func _ready() -> void:
	atacar_rook_timer.wait_time = tiempo_de_ataque
	atacar_rook_timer.connect("timeout", atacar_rook)

func _on_detector_area_entered(area: Area2D) -> void:
	estado_actual = ATACAR
	rook_a_atacar = area.get_parent()
	atacar_rook_timer.start()
	atacar_rook()

func _on_detector_area_exited(area: Area2D) -> void:
	estado_actual = CAMINAR
	rook_a_atacar = null
	atacar_rook_timer.stop()
	
func atacar_rook():
	if rook_a_atacar != null:
		rook_a_atacar.recibir_ataque(ataque)
		atacar_rook_timer.start()
