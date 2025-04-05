@tool

extends "res://addons/rubichart_converter/importer.gd"

func get_name() -> String:
	return "Simfile (*.sm)"
	
func get_extension() -> String:
	return "*.sm"

var special_note_type : String = ""
func convert_chart(_chart : FileAccess, _meta : FileAccess, _events : FileAccess) -> Dictionary:
	if _chart == null:
		main_scene.print_new_line("[ERROR] Chart file was not found!")
		return {}
	
	if _chart.get_error() != OK:
		main_scene.print_new_line("[ERROR] An error has occured while opening this file! Error: " + str(_chart.get_error()))
		return {}
	
	var meta : SongMeta = SongMeta.new()
	meta.Stage = "stage"
	
	var opponent_meta : CharacterMeta = CharacterMeta.new(); opponent_meta.Character = "bf-pixel"; opponent_meta.BarLine = "Opponent"; opponent_meta.Nickname = "Opponent"
	var player_meta : CharacterMeta = CharacterMeta.new(); player_meta.Character = "bf"; player_meta.BarLine = "Player"; player_meta.Nickname = "Player"
	var speaker_meta : CharacterMeta = CharacterMeta.new(); speaker_meta.Character = "gf"; speaker_meta.BarLine = "Speaker"; speaker_meta.Nickname = "Speaker"
	meta.Characters = [opponent_meta, player_meta, speaker_meta]
	
	var charts : Dictionary[String, RubiChart] = {}
	while not _chart.eof_reached():
		var cur_line : String = _chart.get_line()
		if cur_line.is_empty() or cur_line[0] != '#':
			continue

		match cur_line.substr(1, cur_line.find(':') - 1):
			"TITLE":
				meta.Name = cur_line.substr(cur_line.find(':') + 1, cur_line.find(';') - cur_line.find(':') - 1)
				continue
			"ARTIST":
				meta.Artist = cur_line.substr(cur_line.find(':') + 1, cur_line.find(';') - cur_line.find(':') - 1)
				continue
			"OFFSET":
				var value : String =  cur_line.substr(cur_line.find(':') + 1, cur_line.find(';') - cur_line.find(':') - 1)
				if value.is_valid_float():
					meta.Offset = float(value)
				continue
			"BPMS":
				var bpm_info : Array[BpmInfo] = []
				cur_line = cur_line.substr(6)
				while true:
					var split_bpms : PackedStringArray = cur_line.split(",")
					for i in split_bpms.size():
						var bpm_lines : PackedStringArray = split_bpms[i].rstrip(";").split("=")
						if bpm_lines.size() != 2:
							continue
						
						var new_bpm : BpmInfo = BpmInfo.new()
						new_bpm.Time = float(bpm_lines[0]) / 4.0
						new_bpm.Bpm = float(bpm_lines[1])
						bpm_info.push_back(new_bpm)
					
					if cur_line.ends_with(";"):
						break
						
					cur_line = _chart.get_line()
				
				meta.BpmInfo = bpm_info
				continue
			"NOTES":
				var chart : RubiChart = RubiChart.new()
				
				cur_line = _chart.get_line().lstrip(' ')
				var sim_chart_type : PackedStringArray = cur_line.substr(0, cur_line.find(':')).split('-')
				
				cur_line = _chart.get_line().lstrip(' ')
				chart.Charter = cur_line.substr(0, cur_line.find(':'))
				
				cur_line = _chart.get_line().lstrip(' ')
				var diff_name : String = cur_line.substr(0, cur_line.find(':'))
				
				cur_line = _chart.get_line().lstrip(' ')
				var diff_num : String = cur_line.substr(0, cur_line.find(':'))
				chart.Difficulty = int(diff_num) if diff_num.is_valid_int() else 0
				
				cur_line = _chart.get_line().lstrip(' ') # I geniunely don't know what this does sorry
				await load_chart_from_type(chart, sim_chart_type, _chart)
				
				#charts[cur_line.substr(0, cur_line.find(':'))] = chart
				var key_name : String = diff_name.substr(0, 1).to_upper() + diff_name.substr(1)
				key_name += sim_chart_type[0].substr(0, 1).to_upper() + sim_chart_type[0].substr(1)
				key_name += sim_chart_type[1].substr(0, 1).to_upper() + sim_chart_type[1].substr(1)
				charts[key_name] = chart
	
	var final_charts : Dictionary[String, RubiChart] = {}
	
	var difficulties : Array[String] = charts.keys()
	var selected_charts : Dictionary[String, RubiChart] = {}
	for index in await main_scene.open_chart_selector(difficulties):
		var key : String = difficulties[index]
		selected_charts[key] = charts[key]
	
	return {
		"charts": selected_charts,
		"meta": meta,
		"events": EventMeta.new()
	}

func load_chart_from_type(chart : RubiChart, type : PackedStringArray, reader : FileAccess) -> RubiChart:
	var measure_data : Array[PackedStringArray] = []
	
	var line_data : Array[String] = []
	var cur_line : String = ""
	
	while cur_line != ";" or not cur_line.ends_with(";"):
		cur_line = reader.get_line()
		if cur_line.begins_with("//"):
			continue
		
		if special_note_type.is_empty() and (cur_line.contains("M") or cur_line.contains("4")):
			special_note_type = await main_scene.get_line_from_user("Special Note Type", "Enter the name of the note type for special notes:", "Normal")
		
		if cur_line == "," or cur_line == ";":
			measure_data.push_back(PackedStringArray(line_data))
			line_data.clear()
			continue
		
		line_data.push_back(cur_line)
	
	var lane_count : int = 0
	var chart_count : int = 1 if type[1] != "couple" else 2
	match type[0]:
		"dance":
			match type[1]:
				"double", "routine":
					lane_count = 8
				"solo":
					lane_count = 6
				_:
					lane_count = 4
		"pump":
			match type[1]:
				"double":
					lane_count = 10
				"halfdouble":
					lane_count = 6
				_:
					lane_count = 5
	
	var first_chart_notes : Array[NoteData] = []
	var second_chart_notes : Array[NoteData] = []
	
	var hold_notes : Array[NoteData] = []
	hold_notes.resize(lane_count * chart_count)
	for i in measure_data.size():
		var measure : PackedStringArray = measure_data[i]
		for t in measure.size():
			var data : PackedStringArray = measure[t].split("")
			for n in data.size():
				match data[n]:
					"1":
						var note : NoteData = NoteData.new()
						note.Time = i + (float(t) / float(measure.size()))
						note.Lane = n % lane_count
						
						if n < lane_count:
							first_chart_notes.push_back(note)
						else:
							second_chart_notes.push_back(note)
					"M":
						var note : NoteData = NoteData.new()
						note.Time = i + (float(t) / float(measure.size()))
						note.Lane = n % lane_count
						note.Type = special_note_type
						
						if n < lane_count:
							first_chart_notes.push_back(note)
						else:
							second_chart_notes.push_back(note)
					"2": 
						var note : NoteData = NoteData.new()
						note.Time = i + (float(t) / float(measure.size()))
						note.Lane = n % lane_count
						
						hold_notes[n] = note
						
						if n < lane_count:
							first_chart_notes.push_back(note)
						else:
							second_chart_notes.push_back(note)
					"4":
						var note : NoteData = NoteData.new()
						note.Time = i + (float(t) / float(measure.size()))
						note.Lane = n % lane_count
						note.Type = special_note_type
						
						hold_notes[n] = note
						
						if n < lane_count:
							first_chart_notes.push_back(note)
						else:
							second_chart_notes.push_back(note)
					"3":
						if hold_notes[n] != null:
							hold_notes[n].Length = i + (float(t) / float(measure.size())) - hold_notes[n].Time
							hold_notes[n] = null
	
	var first_chart : ChartData = ChartData.new()
	first_chart.Lanes = lane_count
	first_chart.Notes = first_chart_notes
	if second_chart_notes.is_empty():
		first_chart.Name = &"Player"
		chart.Charts = [first_chart]
		return chart
	
	first_chart.Name = &"Opponent"
	var second_chart : ChartData = ChartData.new()
	second_chart.Name = &"Player"
	second_chart.Lanes = lane_count
	second_chart.Notes = second_chart_notes
	
	chart.Charts = [first_chart, second_chart]
	return chart
