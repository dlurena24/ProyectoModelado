class_name Avatar
extends CharacterBody2D

enum {CAMINAR, ATACAR}

var direccion := -1
var estado_actual = CAMINAR
var estado_previo

# Salud
@export var salud_maxima : float = 100.0
var salud_actual : float = 100.0

# Ataque
@export var ataque : float = 20
@export var tiempo_de_ataque : float = 1.3
@export var velocidad : float = 25.0


var rook_a_atacar : Rook_Base

@onready var animacion: AnimationPlayer = $AnimationPlayer
@onready var atacar_rook_timer: Timer = $AtacarRookTimer
@onready var animacion_impacto: AnimationPlayer = $AnimacionImpacto



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
	
	# Salud actual
	salud_actual = salud_maxima

func _on_detector_area_entered(area: Area2D) -> void:
	estado_actual = ATACAR
	rook_a_atacar = area.get_parent()
	await get_tree().create_timer(1.3).timeout
	atacar_rook()

func _on_detector_area_exited(area: Area2D) -> void:
	estado_actual = CAMINAR
	rook_a_atacar = null
	atacar_rook_timer.stop()
	
func atacar_rook():
	if rook_a_atacar != null: # Verifica que aún exista
		rook_a_atacar.recibir_ataque(ataque)
		atacar_rook_timer.start()
			

func recibir_ataque(cantidad: float):
	salud_actual -= cantidad
	
	# Revisa si tiene salud
	if salud_actual <= 0:
		Global.agregar_monedas(75)
		queue_free()
		return
	animacion_impacto.play("impacto")

func _on_end_line_detector_area_entered(area: Area2D) -> void:
	perder_nivel()
	
func perder_nivel():
	print("Nivel perdido!")
	get_tree().change_scene_to_file("res://Framework/GameLost.tscn")
