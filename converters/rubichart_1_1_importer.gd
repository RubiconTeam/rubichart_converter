@tool

extends "res://addons/rubichart_converter/importer.gd"

func get_name() -> String:
	return "RubiChart v1.1"
	
func get_extension() -> String:
	return "*.rbc"
	
func convert_chart(_chart : FileAccess, _meta : FileAccess, _events : FileAccess, _attempt_snapping : bool) -> Dictionary:
	var rbc_check : PackedByteArray = _chart.get_buffer(4)
	var is_valid_chart : bool = rbc_check.decode_u32(0) == 16842752
	if not is_valid_chart:
		if not (rbc_check.get_string_from_utf8() == "RBCN"):
			return {}

		var version : int = _chart.get_32()
		if version == 16843008:
			is_valid_chart = true
		
		if not is_valid_chart:
			return {}
	
	var chart : RubiChart = RubiChart.new()
	chart.Difficulty = _chart.get_32()
	chart.ScrollSpeed = _chart.get_float()

	var charter_length : int = int(_chart.get_32())
	chart.Charter = _chart.get_buffer(charter_length).get_string_from_utf8()

	var note_types_length : int = int(_chart.get_32())
	var note_types : PackedStringArray = []
	for i in note_types_length:
		var type_length : int = int(_chart.get_32())
		note_types.push_back(_chart.get_buffer(type_length).get_string_from_utf8())

	var amtOfCharts : int = int(_chart.get_32())
	var charts : Array[ChartData] = []
	for i in amtOfCharts:
		var individual_chart : ChartData = ChartData.new()

		var name_length : int = int(_chart.get_32())
		individual_chart.Name = _chart.get_buffer(name_length).get_string_from_utf8()
		individual_chart.Lanes = int(_chart.get_32())

		var target_switch_count : int = int(_chart.get_32())
		var target_switches : Array[TargetSwitch] = []
		for j in target_switch_count:
			var target_switch : TargetSwitch = TargetSwitch.new()
			target_switch.Time = _chart.get_float()

			var ts_name_length : int = int(_chart.get_32())
			target_switch.Name = _chart.get_buffer(ts_name_length).get_string_from_utf8()
			target_switches.push_back(target_switch)

		individual_chart.Switches = target_switches

		var sv_change_count : int = int(_chart.get_32())
		var sv_changes : Array[SvChange] = []
		for j in sv_change_count:
			var sv_change : SvChange = SvChange.new()
			sv_change.Time = _chart.get_float()
			sv_change.Multiplier = _chart.get_float()
			sv_changes.push_back(sv_change)

		individual_chart.SvChanges = sv_changes

		var note_count : int = int(_chart.get_32())
		for j in note_count:
			var note : NoteData = NoteData.new()

			var serialized_type : int = _chart.get_8()
			var measure_time : float = _chart.get_float()
			var measure_length : float = 0.0
			note.Lane = int(_chart.get_32())

			if serialized_type >= 4: # Is hold note
				measure_length = _chart.get_float()
				serialized_type -= 4

			match serialized_type:
				1: # Typed note
					note.Type = note_types[int(_chart.get_32())]
				2: # Note with params
					read_note_parameters(_chart, note)
				3: # Typed note with params
					note.Type = note_types[int(_chart.get_32())]
					read_note_parameters(_chart, note)

			if _attempt_snapping:
				individual_chart.AddNoteAtMeasureTime(note, measure_time, measure_length)
			else:
				note.MeasureTime = measure_time
				note.MeasureLength = measure_length
				individual_chart.AddStrayNote(note)

		individual_chart.CleanupSections()
		charts.push_back(individual_chart)

	chart.Charts = charts
	
	var chart_path : String = _chart.get_path()
	return {
		"charts": {chart_path.substr(chart_path.rfind("/") + 1, chart_path.rfind(".")) : chart},
		"events": EventMeta.new(),
		"meta": SongMeta.new()
	}

func read_note_parameters(reader : FileAccess, note : NoteData) -> void:
	var param_count : int = int(reader.get_32())
	for k in param_count:
		var param_name_length : int = int(reader.get_32())
		var param_name : StringName = reader.get_buffer(param_name_length).get_string_from_utf8()
		var param_value_length : int = int(reader.get_32())
		var param_value : Variant = bytes_to_var(reader.get_buffer(param_value_length))
		note.Parameters.set(param_name, param_value)
	