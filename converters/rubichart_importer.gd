@tool

extends "res://addons/rubichart_converter/importer.gd"

func get_name() -> String:
	return "RubiChart Binary"
	
func get_extension() -> String:
	return "*.rbc"
	
func convert_chart(_chart : FileAccess, _meta : FileAccess, _events : FileAccess) -> Dictionary:
	var chart : RubiChart = RubiChart.new()
	chart.LoadBytes(_chart.get_buffer(_chart.get_length()))
	
	var chart_path : String = _chart.get_path()
	return {
		"charts": {chart_path.substr(chart_path.rfind("/") + 1, chart_path.rfind(".")) : chart},
		"events": EventMeta.new(),
		"meta": SongMeta.new()
	}
