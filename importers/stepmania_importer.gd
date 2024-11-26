@tool

extends "res://addons/rubichart_importer/importer.gd"

func get_name() -> String:
	return "Simfile (*.sm)"
	
func get_extension() -> String:
	return ".sm"

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
	var speaker_meta : CharacterMeta = CharacterMeta.new(); speaker_meta.Character = "gf"; speaker_meta.BarLine = ""; speaker_meta.Nickname = "Speaker"
	meta.Characters = [opponent_meta, player_meta, speaker_meta]
	
	var charts : Dictionary[String, RubiChart] = {}
	while not _chart.eof_reached():
		var cur_line : String = _chart.get_line()
		if cur_line[0] != '#':
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
				var beat : String = ""
				var bpm : String = ""
				var read_bpm : bool = false
				cur_line = cur_line.substr(6)
				while true:
					for i in cur_line.length():
						match cur_line[i]:
							_:
								if read_bpm:
									bpm += cur_line[i]
								else:
									beat += cur_line[i]
							"=":
								read_bpm = true
							";", ",":
								var new_bpm : BpmInfo = BpmInfo.new()
								new_bpm.Time = float(beat) / 4.0
								new_bpm.Bpm = float(bpm)
								bpm_info.push_back(new_bpm)
								
								bpm = ""
								beat = ""
					
					if cur_line.ends_with(";"):
						break
					cur_line = _chart.get_line()
				
				meta.BpmInfo = bpm_info
				continue
			"NOTES":
				var chart : RubiChart = RubiChart.new()
				
				cur_line = _chart.get_line().lstrip(' ')
				var sim_chart_type : PackedStringArray = cur_line.substr(0, cur_line.find(':')).split('-')
				
			
	return {}

func create_chart_from_type(type : PackedStringArray) -> RubiChart:
	match type[0]:
		"dance":
			return create_dance_chart(type[1])
	
	return null

func create_dance_chart(type : String) -> RubiChart:
	var chart : RubiChart = RubiChart.new()
	match type:
		"single":
			pass
	
	return chart
