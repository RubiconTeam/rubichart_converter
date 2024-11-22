@tool

extends "res://addons/rubichart_importer/importer.gd"

func get_name() -> String:
	return "Funkin' (Week 7 and below)"
	
func get_extension() -> String:
	return ".json"
	
func convert_chart(_chart : String, _meta : String, _events : String) -> Dictionary:
	var funkin_json : Dictionary = JSON.parse_string(_chart) as Dictionary
	if (not funkin_json.has("song")):
		main_scene.print_new_line("[ERROR] The JSON file given was not a Funkin' Chart!")
		return {}
		
	var chart : RubiChart = RubiChart.new()
	var swag_song : Dictionary = funkin_json.get("song") as Dictionary
	
	var first_bpm : BpmInfo = BpmInfo.new()
	first_bpm.Time = 0.0
	first_bpm.Bpm = swag_song.get("bpm") as float
	
	var bpm_changes : Array[BpmInfo] = [ first_bpm ]
	chart.ScrollSpeed = (swag_song.get("speed", 1.0) as float) * 0.675
	
	var player_notes : Array[NoteData] = []
	var opponent_notes : Array[NoteData] = []
	var speaker_notes : Array[NoteData] = []
	
	var camera_changes : Array[EventData] = []
	
	var last_camera : int = 0
	var measure_time : float = 0.0
	var sections : Array = swag_song.get("notes") as Array
	for i in sections.size():
		var cur_section : Dictionary = sections[i] as Dictionary
		if (bpm_changes.filter(func(bpm:BpmInfo)->bool:return bpm.Time == i).size() == 0 and cur_section.get("changeBPM", false) as bool):
			var new_bpm : BpmInfo = BpmInfo.new(); new_bpm.Time = i; new_bpm.Bpm = cur_section["bpm"] as float; new_bpm.TimeSignatureDenominator = (cur_section.get("lengthInSteps", 16) as int) / 4
			bpm_changes.push_back(new_bpm)
		
		var measure_bpm : float = (bpm_changes.filter(func(bpm:BpmInfo)->bool:return bpm.Time <= i).back() as BpmInfo).Bpm
		var player_section : bool = cur_section.get("mustHitSection") as bool
		var section_camera : int = 1 if player_section else 0
		
		var speaker_section : bool = cur_section.get("gfSection", false) as bool
		if speaker_section:
			section_camera = 2
			
		if last_camera != section_camera:
			var cam_event : EventData = EventData.new(); cam_event.Time = i; cam_event.Name = "Set Camera Focus"; cam_event.Arguments = [section_camera]
			camera_changes.push_back(cam_event)
			
		last_camera = section_camera
		
		var notes : Array = cur_section.get("sectionNotes")
		for n in notes.size():
			var parsed_note : Array = notes[n] as Array
			var note : NoteData = NoteData.new()
			note.Time = (((parsed_note[0] as float) - measure_time) / (60.0 / measure_bpm * 4.0) / 1000.0) + i
			note.Lane = (parsed_note[1] as int) % 4
			note.Length = (parsed_note[2] as float) / (60.0 / measure_bpm * 4.0) / 1000.0
			note.Type = (parsed_note[3] as String) if parsed_note.size() > 3 else "normal"
			
			if (parsed_note[0] as float) < measure_time:
				main_scene.print_new_line("[WARNING] Measure " + str(i) + ", note " + str(n) + ", lane " + str(parsed_note[1] as int) + ": time of " + str(parsed_note[0] as float) + " exceeds calculated measure start time of " + str(measure_time) + "! Calculated milliseconds will be " + str((parsed_note[0] as float) - measure_time) + ", measure " + str(note.MsTime))
		
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
			
		measure_time += Utility.measure_to_ms(1.0, measure_bpm, 4.0)
	
	chart.BpmInfo = bpm_changes
	
	var opponent_chart : IndividualChart = IndividualChart.new(); opponent_chart.Name = "Opponent"; opponent_chart.Notes = opponent_notes; opponent_chart.Lanes = 4
	var player_chart : IndividualChart = IndividualChart.new(); player_chart.Name = "Player"; player_chart.Notes = player_notes; player_chart.Lanes = 4
	var speaker_has_notes : bool = speaker_notes.size() > 0
	if speaker_has_notes:
		var speaker_chart : IndividualChart = IndividualChart.new(); speaker_chart.Name = "Speaker"; speaker_chart.Notes = speaker_notes; speaker_chart.Lanes = 4
		chart.Charts = [opponent_chart, player_chart, speaker_chart]
	else:
		chart.Charts = [opponent_chart, player_chart]
		
	chart.Format()
	
	# Events
	var event_meta : EventMeta = EventMeta.new()
	event_meta.Events = camera_changes
	
	# Song Meta
	var meta : SongMeta = SongMeta.new()
	meta.Stage = swag_song.get("stage", "stage") as String
	meta.PlayableCharts = ["Player", "Opponent"]
	
	var opponent_meta : CharacterMeta = CharacterMeta.new(); opponent_meta.Character = swag_song.get("player2", "Missing"); opponent_meta.BarLine = "Opponent"; opponent_meta.Nickname = "Opponent"
	var player_meta : CharacterMeta = CharacterMeta.new(); player_meta.Character = swag_song.get("player1", "Missing"); player_meta.BarLine = "Player"; player_meta.Nickname = "Player"
	var speaker_meta : CharacterMeta = CharacterMeta.new(); speaker_meta.Character = swag_song.get("gfVersion", "Missing"); speaker_meta.BarLine = "Speaker" if speaker_has_notes else ""; speaker_meta.Nickname = "Speaker"
	meta.Characters = [opponent_meta, player_meta, speaker_meta]
	
	return {
		"chart": chart,
		"events": event_meta,
		"meta": meta
	}
