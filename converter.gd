@abstract class Converter:
	@abstract func get_name() -> String
	
	@abstract func get_new_parameters() -> Dictionary[String, Variant]
	
	@abstract func convert_chart(file_path : String) -> void
