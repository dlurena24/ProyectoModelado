extends Node2D

var nivel_actual : Mundo
var cursor_rook : Cursor_Rook
var celda_valida : bool = false
var mostrar_cursor_rook : bool = false

var rooks_colocados : Dictionary = {}
var panel_rook_actual : PanelRook
var posicion_actual : Vector2i
var celda_actual : Celda_Rook

func _physics_process(_delta: float):
	if cursor_rook != null and mostrar_cursor_rook:
		cursor_rook.global_position = get_global_mouse_position()

func rook_seleccionado(panel_rook: PanelRook) :
	panel_rook_actual = panel_rook
	
	if mostrar_cursor_rook == false:
		#print("Mostrar cursor")
		mostrar_cursor_rook = true
		cursor_rook.actualizar_visuales(panel_rook)
		nivel_actual.mostrar_celdas(true)
	
func actualizar_celda_actual(pos : Vector2i, celda : Celda_Rook):
	_cleanup_dead_rooks()
	cursor_rook.establecer_celda_valida(!rooks_colocados.has(pos))
	posicion_actual = pos
	celda_actual = celda

	
func intentar_colocar_rook() :
	_cleanup_dead_rooks()
	if panel_rook_actual and not rooks_colocados.has(posicion_actual):
		# Crear una instancia de Rook a colocar
		var nuevo_rook = panel_rook_actual.rook_a_colocar.instantiate()
		# Agregar Rook al nodo del mundo
		nivel_actual.rooks.add_child(nuevo_rook)
		# Colocarle la posicion global
		nuevo_rook.global_position = celda_actual.global_position
		# Agregar Rook al diccionario
		rooks_colocados[posicion_actual] = nuevo_rook
		
		# Quitar monedas
		Global.quitar_monedas(panel_rook_actual.precio_monedas)
		
		nuevo_rook.celda_ocupada = posicion_actual
		nuevo_rook.connect("murio", Callable(self, "_on_rook_muerto"))
		
		# Restablecer variables
		panel_rook_actual = null
		celda_actual = null
		mostrar_cursor_rook = false
		nivel_actual.mostrar_celdas(false)
		cursor_rook.actualizar_visuales(null)
		
func _on_rook_muerto(pos: Vector2i):
	if rooks_colocados.has(pos):
		rooks_colocados.erase(pos)

func reset_for_new_level() -> void:
	# Estado de colocación/UI
	celda_valida = false
	mostrar_cursor_rook = false
	panel_rook_actual = null
	posicion_actual = Vector2i.ZERO
	celda_actual = null

	# IMPORTANTÍSIMO: limpiar ocupación
	rooks_colocados.clear()

	# Limpiar visuals si el cursor ya existe
	if cursor_rook:
		cursor_rook.actualizar_visuales(null)


func _cleanup_dead_rooks() -> void:
	# Por si quedaron llaves con nodos ya liberados (seguro extra)
	for k in rooks_colocados.keys():
		var r = rooks_colocados[k]
		if not is_instance_valid(r):
			rooks_colocados.erase(k)
