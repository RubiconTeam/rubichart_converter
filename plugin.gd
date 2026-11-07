@tool
extends EditorPlugin

const ConverterPopup: PackedScene = preload("res://addons/rubichart_converter/converter_popup.tscn")
const ConverterContextMenu: GDScript = preload("res://addons/rubichart_converter/context_menu_plugin.gd")

var _converter_popup_instance: PopupMenu
var _converter_context_menu_instance: EditorContextMenuPlugin

static var instance: EditorPlugin

func _enter_tree() -> void:
	if instance == null:
		instance = self
	
	add_editor_setting("rubichart_converter/general/initial_scroll_multiplier", TYPE_FLOAT, PROPERTY_HINT_NONE, "", 0.6667)
	#add_editor_setting("rubichart_converter/general/convert_camera_changes_into_animation", TYPE_BOOL, PROPERTY_HINT_NONE, "", true)
	
	# most likely removed after context menu is fully working
	_converter_popup_instance = ConverterPopup.instantiate()
	add_tool_submenu_item("Convert to RubiChart", _converter_popup_instance)
	
	_converter_context_menu_instance = ConverterContextMenu.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _converter_context_menu_instance)

func _exit_tree() -> void:
	if instance != null:
		instance = null
	
	if _converter_popup_instance == null or _converter_context_menu_instance == null:
		return
	
	remove_tool_menu_item("Convert to RubiChart")
	remove_context_menu_plugin(_converter_context_menu_instance)

func add_editor_setting(name : String, type : Variant.Type, hint : PropertyHint, hint_string : String = "", default_value : Variant = null) -> void:
	var editor_settings: EditorSettings = get_editor_interface().get_editor_settings()
	
	if not editor_settings.has_setting(name):
		editor_settings.set_setting(name, default_value)
	
	editor_settings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})

	editor_settings.set_initial_value(name, default_value, false)
