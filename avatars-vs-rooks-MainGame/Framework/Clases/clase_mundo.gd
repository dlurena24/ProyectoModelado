class_name Mundo
extends Node2D

@export var oleada_actual : int = 0
@export var cantidad_de_oleadas : int = 5
@export var enemigos_por_oleada : Array[int] = [2]
@export var tiempo_oleadas : Array[float] = [3.0]

var timer_oleada : Timer

# Sistema de enemigos
var enemigos_totales_oleada : int = 0
var enemigos_actuales : int = 0
var enemigos_totales : int = 0

@export var nodo_lineas : Node2D

func inicializar_mundo():
	#Crear temporizador
	timer_oleada = Timer.new()
	timer_oleada.one_shot = true
	timer_oleada.autostart = false
	timer_oleada.wait_time = tiempo_oleadas[0]
	
	timer_oleada.timeout.connect(inicializar_oleada)
	timer_oleada.start()
	
	# Calcular enemigos totales
	for enemigos in enemigos_por_oleada:
		enemigos_totales += enemigos
	
func inicializar_oleada():
	# Revisar si hay nueva oleada
	if (oleada_actual < cantidad_de_oleadas):
		return
		
	if enemigos_por_oleada.size() < oleada_actual or tiempo_oleadas.size() < oleada_actual:
		return
		
	# Spawnear enemigos
	spawnear_enemigos(enemigos_por_oleada[oleada_actual])
	
	timer_oleada.wait_time = tiempo_oleadas[oleada_actual]
	timer_oleada.start() 

func spawnear_enemigos(total : int):
	pass

func enemigo_abatido():
	enemigos_actuales -= 1
