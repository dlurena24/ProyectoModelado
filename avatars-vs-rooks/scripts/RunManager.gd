extends Node

var is_running: bool = false
var total_elapsed_ms: int = 0           # acumulado (sin contar el segmento activo)
var segment_start_ticks_ms: int = 0     # inicio del segmento activo (ticks)
var current_level_index: int = 0        # 0,1,2 (nivel 1,2,3)
var pending_next_scene_path: String = ""

func start_new_run() -> void:
	is_running = true
	total_elapsed_ms = 0
	current_level_index = 0
	segment_start_ticks_ms = 0
	resume_segment()

func resume_segment() -> void:
	if not is_running:
		return
	if segment_start_ticks_ms == 0:
		segment_start_ticks_ms = Time.get_ticks_msec()

func pause_segment() -> void:
	if not is_running:
		return
	if segment_start_ticks_ms != 0:
		total_elapsed_ms += (Time.get_ticks_msec() - segment_start_ticks_ms)
		segment_start_ticks_ms = 0

func get_total_elapsed_ms() -> int:
	if not is_running:
		return 0
	var t := total_elapsed_ms
	if segment_start_ticks_ms != 0:
		t += (Time.get_ticks_msec() - segment_start_ticks_ms)
	return max(t, 0)

func restore_from_save(saved_total_ms: int, saved_level_index: int) -> void:
	is_running = true
	total_elapsed_ms = max(saved_total_ms, 0)
	current_level_index = max(saved_level_index, 0)
	segment_start_ticks_ms = 0  # lo arrancamos cuando el nivel ya esté cargado
	
func end_run() -> void:
	is_running = false
	total_elapsed_ms = 0
	segment_start_ticks_ms = 0
	current_level_index = 0
	pending_next_scene_path = ""
