@tool

extends "res://addons/rubichart_converter/importer.gd"

func get_name() -> String:
	return "Funkin' (Week 7 and below)"
	
func get_extension() -> String:
	return "*.json"
	
func convert_chart(_chart : FileAccess, _meta : FileAccess, _events : FileAccess, _attempt_snapping : bool) -> Dictionary:
	if _chart == null:
		main_scene.print_new_line("[ERROR] Chart file was not found!")
		return {}
	
	if _chart.get_error() != OK:
		main_scene.print_new_line("[ERROR] An error has occured while opening this file! Error: " + str(_chart.get_error()))
		return {}
	
	var funkin_json : JSON = JSON.new()
	if funkin_json.parse(_chart.get_as_text(true)) != OK:
		main_scene.print_new_line("[ERROR] An error has occured parsing this file! Error: " + str(funkin_json.get_error_message()))
		return {}
	
	var parsed_json : Dictionary = funkin_json.data as Dictionary
	if (not parsed_json.has("song")):
		main_scene.print_new_line("[ERROR] The JSON file given was not a Funkin' Chart!")
		return {}
		
	var chart : RubiChart = RubiChart.new()
	var swag_song : Dictionary = parsed_json.get("song") as Dictionary
	
	var first_bpm : TimeChange = TimeChange.new()
	first_bpm.Time = 0.0
	first_bpm.Bpm = swag_song.get("bpm") as float
	
	var bpm_changes : Array[TimeChange] = [ first_bpm ]
	chart.ScrollSpeed = (swag_song.get("speed", 1.0) as float) * 0.675
	
	var player_notes : Array[NoteData] = []
	var opponent_notes : Array[NoteData] = []
	var speaker_notes : Array[NoteData] = []
	
	var camera_changes : Array[EventData] = []
	
	var last_camera : int = 0
	var sections : Array = swag_song.get("notes") as Array
	for i in sections.size(): # Create BPMs first
		var cur_section : Dictionary = sections[i] as Dictionary
		if (bpm_changes.filter(func(bpm:TimeChange)->bool:return bpm.Time == i).size() == 0 and cur_section.get("changeBPM", false) as bool):
			var new_bpm : TimeChange = TimeChange.new(); new_bpm.Time = i; new_bpm.Bpm = cur_section["bpm"] as float; new_bpm.TimeSignatureDenominator = (cur_section.get("lengthInSteps", 16) as int) / 4
			bpm_changes.push_back(new_bpm)
	
	for i in sections.size():
		var cur_section : Dictionary = sections[i] as Dictionary
		var measure_bpm : float = (bpm_changes.filter(func(bpm:TimeChange)->bool:return bpm.Time <= i).back() as TimeChange).Bpm
		var player_section : bool = cur_section.get("mustHitSection") as bool
		var section_camera : int = 1 if player_section else 0
		
		var speaker_section : bool = cur_section.get("gfSection", false) as bool
		if speaker_section:
			section_camera = 2
			
		if last_camera != section_camera:
			var cam_focus_name : StringName = &""
			match section_camera:
				0:
					cam_focus_name = &"Opponent"
				1:
					cam_focus_name = &"Player"
				2:
					cam_focus_name = &"Speaker"
			
			var cam_event : EventData = EventData.new(); cam_event.Time = i; cam_event.Name = "SetCameraFocus"; cam_event.Arguments = { "Focus": cam_focus_name }
			camera_changes.push_back(cam_event)
			
		last_camera = section_camera
		
		var notes : Array = cur_section.get("sectionNotes")
		for n in notes.size():
			var parsed_note : Array = notes[n] as Array
			var note : NoteData = NoteData.new()
			note.MeasureTime = Utility.ms_to_measures(parsed_note[0] as float, bpm_changes)
			note.Lane = (parsed_note[1] as int) % 4
			note.MeasureLength = Utility.get_length_from_ms(parsed_note[0] as float, (parsed_note[0] as float) + (parsed_note[2] as float), bpm_changes)
			note.Type = (parsed_note[3] as String) if parsed_note.size() > 3 else "Normal"
			
			var lane : int = parsed_note[1] as int
			if lane <= 3:
				if player_section:
					player_notes.push_back(note)
				else:
					if speaker_section:
						speaker_notes.push_back(note)
					else:
						opponent_notes.push_back(note)
			elif lane <= 7:
				if player_section:
					opponent_notes.push_back(note)
				else:
					player_notes.push_back(note)
			else:
				speaker_notes.push_back(note)
	
	var opponent_chart : ChartData = ChartData.new(); opponent_chart.Name = "Opponent"; opponent_chart.Lanes = 4
	for note in opponent_notes:
		if _attempt_snapping:
			opponent_chart.AddNoteAtMeasureTime(note, note.MeasureTime, note.MeasureLength)
		else:
			opponent_chart.AddStrayNote(note)
	
	var player_chart : ChartData = ChartData.new(); player_chart.Name = "Player"; player_chart.Lanes = 4
	for note in player_notes:
		if _attempt_snapping:
			player_chart.AddNoteAtMeasureTime(note, note.MeasureTime, note.MeasureLength)
		else:
			player_chart.AddStrayNote(note)
	
	var speaker_has_notes : bool = speaker_notes.size() > 0
	if speaker_has_notes:
		var speaker_chart : ChartData = ChartData.new(); speaker_chart.Name = "Speaker"; speaker_chart.Lanes = 4
		for note in speaker_notes:
			if _attempt_snapping:
				speaker_chart.AddNoteAtMeasureTime(note, note.MeasureTime, note.MeasureLength)
			else:
				speaker_chart.AddStrayNote(note)
		
		chart.Charts = [opponent_chart, player_chart, speaker_chart]
	else:
		chart.Charts = [opponent_chart, player_chart]
	
	# Events
	var event_meta : EventMeta = EventMeta.new()
	event_meta.Events = camera_changes
	
	# Song Meta
	var meta : SongMeta = SongMeta.new()
	meta.Stages = [swag_song.get("stage", "stage") as String]
	meta.PlayableCharts = ["Player", "Opponent"]
	meta.TimeChanges = bpm_changes
	meta.Events = event_meta
	
	var opponent_meta : CharacterMeta = CharacterMeta.new(); opponent_meta.Character = swag_song.get("player2", "Missing"); opponent_meta.BarLine = "Opponent"; opponent_meta.Nickname = "Opponent"
	var player_meta : CharacterMeta = CharacterMeta.new(); player_meta.Character = swag_song.get("player1", "Missing"); player_meta.BarLine = "Player"; player_meta.Nickname = "Player"
	var speaker_meta : CharacterMeta = CharacterMeta.new(); speaker_meta.Character = swag_song.get("gfVersion", "Missing"); speaker_meta.BarLine = "Speaker"; speaker_meta.Nickname = "Speaker"
	meta.Characters = [opponent_meta, player_meta, speaker_meta]
	
	return {
		"charts": {"Mania-Chart": chart},
		"events": event_meta,
		"meta": meta
	}
