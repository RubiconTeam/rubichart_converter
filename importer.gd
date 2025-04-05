@tool

extends RefCounted

const PluginScene = preload("res://addons/rubichart_converter/plugin_scene.gd")
const Utility = preload("res://addons/rubichart_converter/utility.gd")

var main_scene : PluginScene

func get_name() -> String:
	return ""
	
func get_extension() -> String:
	return ""
	
func needs_meta_file() -> bool:
	return false
	
func get_meta_extension() -> String:
	return ""
	
func needs_events_file() -> bool:
	return false
	
func get_events_extension() -> String:
	return ""

func needs_snapping() -> bool:
	return true

func convert_chart(_chart : FileAccess, _meta : FileAccess, _events : FileAccess, _attempt_snapping : bool) -> Dictionary:
	return {}
