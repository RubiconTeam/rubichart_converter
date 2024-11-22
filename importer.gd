@tool

extends RefCounted

const PluginScene = preload("res://addons/rubichart_importer/plugin_scene.gd")
const Utility = preload("res://addons/rubichart_importer/utility.gd")

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

func convert_chart(_chart : String, _meta : String, _events : String) -> Dictionary:
	return {}
