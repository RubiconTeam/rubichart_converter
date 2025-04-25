@tool

extends "res://addons/rubichart_converter/importer.gd"

func get_name() -> String:
	return "Funkin' (Week-End 1 and later)"
	
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
	
	var vslice_meta_json : JSON = JSON.new()
	if vslice_meta_json.parse(_meta.get_as_text(true)) != OK:
		main_scene.print_new_line("[ERROR] An error has occured parsing the metadata file! Error: " + str(vslice_meta_json.get_error_message()))
		return {}
	
	var vslice_meta : Dictionary = vslice_meta_json.data as Dictionary
	var vslice_play_data : Dictionary = vslice_meta.get("playData") as Dictionary
	
	var vslice_difficulties : PackedStringArray = vslice_play_data.get("difficulties", []) as PackedStringArray
	var ratings : Dictionary = vslice_play_data.get("ratings") as Dictionary
	var formatted_diffs : Array[String] = []
	for i in vslice_difficulties.size():
		formatted_diffs.push_back(vslice_difficulties[i] + " (" + str(ratings[vslice_difficulties[i]]) + ")")
	
	var difficulties : Array[String] = []
	for index in await main_scene.open_chart_selector(formatted_diffs):
		difficulties.push_back(vslice_difficulties[index])
	
	var time_format : String = vslice_meta.get("timeFormat", "ms") as String
	var vslice_bpm_info : Array = vslice_meta.get("timeChanges") as Array
	
	var first_vslice_bpm : Dictionary = vslice_bpm_info[0] as Dictionary
	var first_bpm : TimeChange = TimeChange.new()
	first_bpm.Time = 0.0
	first_bpm.Bpm = first_vslice_bpm.get("bpm") as float
	first_bpm.TimeSignatureNumerator = first_vslice_bpm.get("n") as int
	first_bpm.TimeSignatureDenominator = first_vslice_bpm.get("d") as int
	
	var bpm_info : Array[TimeChange] = [first_bpm]
	for i in range(1, vslice_bpm_info.size()):
		var vslice_bpm : Dictionary = vslice_bpm_info[i] as Dictionary
		var bpm : TimeChange = TimeChange.new()
		bpm.Time = get_measure_by_format(vslice_bpm.get("t") as float, bpm_info, time_format)
		bpm.Bpm = vslice_bpm.get("bpm") as float
		bpm.TimeSignatureNumerator = vslice_bpm.get("n") as int
		bpm.TimeSignatureDenominator = vslice_bpm.get("d") as int
	
	var vslice_chart_json : JSON = JSON.new()
	if vslice_chart_json.parse(_chart.get_as_text(true)) != OK:
		main_scene.print_new_line("[ERROR] An error has occured parsing the chart file! Error: " + str(vslice_meta_json.get_error_message()))
		return {}
	
	var vslice_charts : Dictionary = vslice_chart_json.data as Dictionary
	var scroll_speeds : Dictionary = vslice_charts.get("scrollSpeed") as Dictionary
	
	var charts : Dictionary[String, RubiChart] = {}
	for difficulty in difficulties:
		var chart : RubiChart = RubiChart.new()
		chart.Charter = vslice_meta.get("charter") as String
		chart.Difficulty = ratings[difficulty]
		chart.ScrollSpeed = (scroll_speeds[difficulty] as float) * 0.675
		
		var player_chart : ChartData = ChartData.new(); player_chart.Name = "Player"
		var opponent_chart : ChartData = ChartData.new(); opponent_chart.Name = "Opponent"
		
		var player_notes : Array[NoteData] = []
		var opponent_notes : Array[NoteData] = []
		
		var vslice_notes : Array = (vslice_charts.get("notes") as Dictionary).get(difficulty) as Array
		for vslice_note in vslice_notes:
			var note : NoteData = NoteData.new()
			note.MeasureTime = get_measure_by_format(vslice_note.get("t") as float, bpm_info, time_format)
			note.Lane = (vslice_note.get("d") as int) % 4
			note.MeasureLength = get_length_by_format(vslice_note.get("t") as float, (vslice_note.get("t") as float) + (vslice_note.get("l", 0.0) as float), bpm_info, time_format)
			note.Type = vslice_note.get("k", "Normal") as String
			
			var lane : int = vslice_note.get("d") as int
			if lane <= 3:
				player_notes.push_back(note)
			elif lane <= 7:
				opponent_notes.push_back(note)
		
		for note in player_notes:
			if _attempt_snapping:
				player_chart.AddNoteAtMeasureTime(note, note.MeasureTime, note.MeasureLength)
			else:
				player_chart.AddStrayNote(note)

		for note in opponent_notes:
			if _attempt_snapping:
				opponent_chart.AddNoteAtMeasureTime(note, note.MeasureTime, note.MeasureLength)
			else:
				opponent_chart.AddStrayNote(note)

		chart.Charts = [opponent_chart, player_chart]
		charts["Mania-" + difficulty[0].to_upper() + difficulty.substr(1)] = chart
	
	# Events
	var vslice_events : Array = vslice_charts.get("events") as Array
	var events : EventMeta = EventMeta.new()
	var event_list : Array[EventData] = []
	for i in vslice_events.size():
		var vslice_event : Dictionary = vslice_events[i] as Dictionary
		var event : EventData = get_rubicon_event(vslice_event, bpm_info, time_format)
		
		if event != null:
			event_list.push_back(event)
			continue
		
		event = EventData.new()
		event.Time = get_measure_by_format(vslice_event.get("t") as float, bpm_info, time_format)
		event.Name = vslice_event.get("e") as String
		
		var vslice_arguments : Dictionary = vslice_event.get("v") as Dictionary
		for argument in vslice_arguments.keys():
			event.Arguments[argument] = vslice_arguments[argument]
			
		event_list.push_back(event)
	
	events.Events = event_list
	
	# Song Meta
	var meta : SongMeta = SongMeta.new()
	meta.Name = vslice_meta.get("songName") as String
	meta.Artist = vslice_meta.get("artist") as String
	meta.Stage = vslice_play_data.get("stage") as String
	meta.TimeChange = bpm_info
	
	var vslice_noteskin : String = vslice_play_data.get("noteStyle") as String
	if vslice_noteskin == "default":
		vslice_noteskin = ProjectSettings.get_setting("rubicon/rulesets/mania/default_note_skin") as String
		
	meta.NoteSkin = vslice_noteskin
	
	var vslice_chars : Dictionary = vslice_play_data.get("characters") as Dictionary
	var player_meta : CharacterMeta = CharacterMeta.new(); player_meta.Nickname = "Player"; player_meta.BarLine = "Player";player_meta.Character = vslice_chars.get("player", "bf") as String
	var speaker_meta : CharacterMeta = CharacterMeta.new(); speaker_meta.Nickname = "Speaker"; player_meta.BarLine = "Speaker";speaker_meta.Character = vslice_chars.get("girlfriend", "gf") as String
	var opponent_meta : CharacterMeta = CharacterMeta.new(); opponent_meta.Nickname = "Opponent"; player_meta.BarLine = "Opponent";player_meta.Character = vslice_chars.get("opponent", "bf-pixel") as String
	meta.Characters = [opponent_meta, player_meta, speaker_meta]
	
	return {
		"charts": charts,
		"events": events,
		"meta": meta
	}

func get_rubicon_event(vslice_event : Dictionary, bpm_info : Array[TimeChange], time_format : String) -> EventData:
	var name : String =  vslice_event.get("e") as String
	var vslice_arguments : Dictionary = vslice_event.get("v") as Dictionary
	match name:
		"FocusCamera":
			var event : EventData = EventData.new()
			event.Time = get_measure_by_format(vslice_event.get("t") as float, bpm_info, time_format)
			if vslice_arguments.get("x", 0.0) != 0.0 or vslice_arguments.get("y", 0.0) != 0.0:
				event.Name = &"Set Camera Position"
				event.Arguments[&"X"] = vslice_arguments.get("x", 0.0)
				event.Arguments[&"Y"] = vslice_arguments.get("y", 0.0)
			else:
				event.Name = &"SetCameraFocus"
				
				var vslice_char_focus : int = vslice_arguments.get("char") as int
				event.Arguments[&"Focus"] = &"Opponent" if vslice_char_focus == 1 else &"Player"
			
			return event
	
	return null

func get_measure_by_format(time : float, bpm_changes : Array[TimeChange], time_format : String) -> float:
	match time_format:
		"ticks": # TODO: Do this later
			return 0.0
		"float": # TODO: Do this later
			return 0.0
		"ms":
			return Utility.ms_to_measures(time, bpm_changes)
	
	return 0.0
	
func get_length_by_format(start : float, end : float, bpm_changes : Array[TimeChange], time_format : String) -> float:
	match time_format:
		"ticks": # TODO: Do this later
			return 0.0
		"float": # TODO: Do this later
			return 0.0
		"ms":
			return Utility.get_length_from_ms(start, end, bpm_changes)
	
	return 0.0
