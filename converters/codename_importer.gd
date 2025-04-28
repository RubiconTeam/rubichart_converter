@tool

extends "res://addons/rubichart_converter/importer.gd"

func get_name() -> String:
	return "Codename Engine"
	
func get_extension() -> String:
	return "*.json"
	
func needs_meta_file() -> bool:
	return true
	
func get_meta_extension() -> String:
	return "*.json"

func convert_chart(_chart : FileAccess, _meta : FileAccess, _events : FileAccess, _attempt_snapping : bool) -> Dictionary:
	if _meta == null:
		main_scene.print_new_line("[ERROR] Metadata file was not found!")
		return {}
	
	if _meta.get_error() != OK:
		main_scene.print_new_line("[ERROR] An error has occured while opening the metadata file! Error: " + str(_meta.get_error()))
		return {}
	
	var cne_meta_json : JSON = JSON.new()
	if cne_meta_json.parse(_meta.get_as_text(true)) != OK:
		main_scene.print_new_line("[ERROR] An error has occured parsing the metadata file! Error: " + str(cne_meta_json.get_error_message()))
		return {}
	
	var cne_meta : Dictionary = cne_meta_json.data as Dictionary
	
	var meta : SongMeta = SongMeta.new()
	meta.RawName = cne_meta.get("name", cne_meta.get("displayName", "")) as String
	meta.Name = cne_meta.get("displayName", meta.Name) as String
	
	var first_bpm : TimeChange = TimeChange.new()
	first_bpm.Time = 0.0
	first_bpm.Bpm = cne_meta.get("bpm") as float
	first_bpm.TimeSignatureNumerator = cne_meta.get("beatsPerMeasure", 4) as int
	first_bpm.TimeSignatureDenominator = (cne_meta.get("stepsPerBeat", 16) as int) / first_bpm.TimeSignatureNumerator
	var bpm_info : Array[TimeChange] = [first_bpm]
	
	if _chart == null:
		main_scene.print_new_line("[ERROR] Chart file was not found!")
		return {}
	
	if _chart.get_error() != OK:
		main_scene.print_new_line("[ERROR] An error has occured while opening the chart file! Error: " + str(_chart.get_error()))
		return {}
	
	var cne_chart_json : JSON = JSON.new()
	if cne_chart_json.parse(_chart.get_as_text(true)) != OK:
		main_scene.print_new_line("[ERROR] An error has occured parsing the chart file! Error: " + str(cne_chart_json.get_error_message()))
		return {}
	
	# Quick run-through for barline names
	var cne_chart_names : Dictionary[int, StringName] = {}
	var cne_chart_meta : Dictionary = cne_chart_json.data as Dictionary
	var cne_charts : Array = cne_chart_meta.get("strumLines") as Array
	for i in cne_charts.size():
		var current_cne_chart : Dictionary = cne_charts[i] as Dictionary
		var cne_chart_type : int = current_cne_chart.get("type") as int
		if cne_chart_names.has(cne_chart_type):
			continue
		
		cne_chart_names[cne_chart_type] = current_cne_chart.get("position") as StringName
	
	var note_types : Array = ["Normal"]
	note_types.append_array(cne_chart_meta.get("noteTypes") as Array)
	
	# Events
	var cne_events : Array = cne_chart_meta.get("events", []) as Array
	var events : Array[EventData] = []
	for cne_event in cne_events:
		var current_cne_event : Dictionary = cne_event as Dictionary
		var cne_event_name : StringName = current_cne_event.get("name") as StringName
		var cne_event_ms : float = current_cne_event.get("time") as float
		var cne_event_params : Array = current_cne_event.get("params") as Array
		
		if cne_event_name == &"BPM Change":
			var bpm : TimeChange = TimeChange.new()
			bpm.Time = Utility.ms_to_measures(cne_event_ms, bpm_info)
			bpm.Bpm = cne_event_params[0] as float
			bpm.TimeSignatureNumerator = first_bpm.TimeSignatureNumerator
			bpm.TimeSignatureDenominator = first_bpm.TimeSignatureDenominator
			continue
		
		match cne_event_name:
			"Camera Movement":
				var event : EventData = EventData.new()
				event.Time = Utility.ms_to_measures(cne_event_ms, bpm_info)
				event.Name = &"SetCameraFocus"
				event.Arguments = { &"Focus": cne_chart_names[cne_event_params[0] as int] }
				events.push_back(event)
				continue
		
		var event : EventData = EventData.new()
		event.Name = cne_event_name
		event.Time = Utility.ms_to_measures(cne_event_ms, bpm_info)
		for i in cne_event_params.size():
			event.Arguments[str(i) as StringName] = cne_event_params[i]
		
		events.push_back(event)
	
	var chart : RubiChart = RubiChart.new()
	var charts : Array[ChartData] = []
	var characters : Array[CharacterMeta] = []
	var chart_types : Dictionary[int, String] = {}
	for i in cne_charts.size():
		var current_cne_chart : Dictionary = cne_charts[i] as Dictionary
		var ind_chart : ChartData = ChartData.new()
		ind_chart.Name = current_cne_chart.get("position", ind_chart.Name) as StringName
		
		var cne_chart_chars : Array = current_cne_chart.get("characters") as Array
		for cne_char in cne_chart_chars:
			var chara : CharacterMeta = CharacterMeta.new()
			chara.Character = cne_char
			chara.BarLine = ind_chart.Name
			chara.Nickname = ind_chart.Name
			characters.push_back(chara)
		
		var cne_chart_type : int = current_cne_chart.get("type") as int
		if not chart_types.has(cne_chart_type):
			chart_types[cne_chart_type] = ind_chart.Name
		
		var notes : Array[NoteData] = []
		var cne_chart_notes : Array = current_cne_chart.get("notes") as Array
		if cne_chart_notes.is_empty():
			continue
		
		for cne_note in cne_chart_notes:
			var current_cne_note : Dictionary = cne_note as Dictionary
			var cne_note_time : float = current_cne_note.get("time") as float
			var cne_note_length : float = current_cne_note.get("sLen") as float
			var cne_note_type : int = current_cne_note.get("type") as int
			
			var note : NoteData = NoteData.new()
			note.MeasureTime = Utility.ms_to_measures(cne_note_time, bpm_info)
			note.MeasureLength = Utility.get_length_from_ms(cne_note_time, cne_note_time + cne_note_length, bpm_info)
			note.Lane = current_cne_note.get("id") as int 
			note.Type = note_types[cne_note_type]
			notes.push_back(note)
			
			ind_chart.Lanes = maxi(note.Lane + 1, ind_chart.Lanes)
		
		for note in notes:
			if _attempt_snapping:
				ind_chart.AddNoteAtMeasureTime(note, note.MeasureTime, note.MeasureLength)
			else:
				ind_chart.AddStrayNote(note)

		charts.push_back(ind_chart)
	
	chart.Charts = charts
	chart.ScrollSpeed = (cne_chart_meta.get("scrollSpeed", 1.0) as float) * 0.675
	
	meta.Characters = characters
	meta.Stages = [cne_chart_meta.get("stage") as String]
	meta.TimeChanges = bpm_info
	
	meta.PlayableCharts = [chart_types[1], chart_types[0]] if (cne_meta.get("opponentModeAllowed", false) as bool) else [chart_types[1]]
	
	var event_meta : EventMeta = EventMeta.new()
	event_meta.Events = events
	
	return {
		"charts": { "Mania-Chart": chart },
		"meta": meta,
		"events": event_meta
	}
