extends ConverterBase.Converter

const ConverterBase = preload("res://addons/rubichart_converter/converter.gd")

func get_name() -> String:
	return ""

func get_new_parameters() -> Dictionary[String, Variant]:
	return Dictionary()

func convert_chart(file_path : String) -> void:
	pass
