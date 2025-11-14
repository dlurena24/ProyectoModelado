extends Node

var last_scene: Node = null

func _ready() -> void:
	set_process(true)
	_tag_ui_text(get_tree().root)
	GlobalSettings.update_theme()
	last_scene = get_tree().current_scene

func _process(_delta: float) -> void:
	var cur := get_tree().current_scene
	if cur and cur != last_scene:
		last_scene = cur
		await get_tree().process_frame
		_tag_ui_text(cur)
		GlobalSettings.update_theme()

func _tag_ui_text(node: Node) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is RichTextLabel or child is CheckBox or child is CheckButton or child is OptionButton or child is LineEdit:
			if not child.is_in_group("ui_text"):
				child.add_to_group("ui_text")
		_tag_ui_text(child)
