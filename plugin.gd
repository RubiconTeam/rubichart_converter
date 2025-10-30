@tool
extends EditorPlugin

const ConverterPopup : PackedScene = preload("res://addons/rubichart_converter/converter_popup.tscn")

var _converter_popup_instance : PopupMenu

func _enter_tree() -> void:
	_converter_popup_instance = ConverterPopup.instantiate()
	add_tool_submenu_item("Convert to RubiChart", _converter_popup_instance)

func _exit_tree() -> void:
	if _converter_popup_instance == null:
		return
	
	remove_tool_menu_item("Convert to RubiChart")
