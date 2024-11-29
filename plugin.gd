@tool
extends EditorPlugin

var scene : PackedScene = preload("res://addons/rubichart_converter/PluginScene.tscn")
var editor_node : Node
var editor_settings : EditorSettings

func _enter_tree() -> void:
	editor_settings = EditorInterface.get_editor_settings()
	add_txt_extension("sm")
	
	editor_node = scene.instantiate()
	add_control_to_bottom_panel(editor_node, "Convert")
	pass

func _exit_tree() -> void:
	remove_control_from_bottom_panel(editor_node)
	editor_node.queue_free()
	
	remove_txt_extension("sm")

func add_txt_extension(ext : String) -> void:
	var txt_extensions : Array = Array((editor_settings.get_setting("docks/filesystem/textfile_extensions") as String).split(","))
	if not txt_extensions.has(ext):
		txt_extensions.push_back(ext)
	var txt_ext_str : String = ""
	for txt_ext in txt_extensions:
		if not (txt_ext as String).is_empty():
			txt_ext_str += txt_ext + ","
	editor_settings.set_setting("docks/filesystem/textfile_extensions", txt_ext_str)

func remove_txt_extension(ext : String) -> void:
	var txt_extensions : Array = Array((editor_settings.get_setting("docks/filesystem/textfile_extensions") as String).split(","))
	txt_extensions.erase(ext)
	var txt_ext_str : String = ""
	for txt_ext in txt_extensions:
		if not (txt_ext as String).is_empty():
			txt_ext_str += txt_ext + ","
	editor_settings.set_setting("docks/filesystem/textfile_extensions", txt_ext_str)
