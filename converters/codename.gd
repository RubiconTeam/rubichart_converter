static func get_new_parameters() -> Dictionary[String, Variant]:
	return Dictionary()

static func needs_metadata() -> bool:
	return true

static func convert_chart(args: Array[String]) -> void:
	print("it has reacheneded "+str(args))
	var file_path: String = args[0]
	var chart_text: String = FileAccess.get_file_as_string(file_path)
	var chart_parse: Dictionary = JSON.parse_string(chart_text)
	
	

static func is_equal_approx_with_tolerance(a : float, b : float, tolerance : float) -> bool:
	if a == b:
		return true
	
	return absf(a - b) < tolerance

static func chart_add_note_at_measure_time(chart : RubiChart, note : RubiChartNote, measure_time : float, length : float) -> void:
	var base_measure : int = floori(measure_time)
	var measure_offset : float = measure_time - base_measure
	
	var offset : int = clampi(roundi(measure_offset * RubiChart.quants.back()), 0, RubiChart.quants.back() - 1)
	var quant : RubiChart.Quant = RubiChart.quants.back()
	for cur_quant in RubiChart.quants:
		var result : float = measure_offset * cur_quant
		var is_snapped : bool = fmod(result, 1) == 0
		if not is_snapped:
			var rounded_result : int = roundi(result)
			if not is_equal_approx_with_tolerance(result, rounded_result, 0.1):
				continue
			
			offset = rounded_result
			quant = cur_quant
			break
		
		offset = result
		quant = cur_quant
		break
	
	RubiChartEditorFunctions.chart_add_note_start(chart, note, base_measure, offset, quant)
	if length <= 0:
		return
	
	base_measure = floori(measure_time + length)
	measure_offset = measure_time + length - base_measure
	
	offset = clampi(roundi(measure_offset * RubiChart.quants.back()), 0, RubiChart.quants.back() - 1)
	quant = RubiChart.quants.back()
	for cur_quant in RubiChart.quants:
		var result : float = measure_offset * cur_quant
		var is_snapped : bool = fmod(result, 1) == 0
		if not is_snapped:
			var rounded_result : int = roundi(result)
			if not is_equal_approx_with_tolerance(result, rounded_result, 0.1):
				continue
			
			offset = rounded_result
			quant = cur_quant
			break
		
		offset = result
		quant = cur_quant
		break
	
	RubiChartEditorFunctions.chart_add_note_end(chart, note, base_measure, offset, quant)
