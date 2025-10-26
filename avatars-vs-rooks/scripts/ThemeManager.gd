extends Node

var last_scene: Node = null

func _ready():
	set_process(true)
	_add_ui_text_nodes(get_tree().root)
	last_scene = get_tree().current_scene

func _process(_delta):
	var current_scene = get_tree().current_scene
	if current_scene != last_scene and current_scene != null:
		last_scene = current_scene
		await get_tree().process_frame
		_add_ui_text_nodes(current_scene)
	
	# Mantener colores sincronizados
	_apply_text_colors()

# --- Añade nodos al grupo 'ui_text' ---
func _add_ui_text_nodes(node: Node):
	for child in node.get_children():
		if child is Label or child is Button or child is RichTextLabel or child is CheckButton or child is OptionButton or child is LineEdit:
			if not child.is_in_group("ui_text"):
				child.add_to_group("ui_text")
		_add_ui_text_nodes(child)

# --- Aplica color global del texto a todos los elementos del grupo ---
func _apply_text_colors():
	for node in get_tree().get_nodes_in_group("ui_text"):
		if node is Label or node is Button or node is RichTextLabel or node is CheckButton or node is OptionButton or node is LineEdit:
			node.add_theme_color_override("font_color", GlobalSettings.text_color)
