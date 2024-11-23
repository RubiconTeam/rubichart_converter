static func measure_to_ms(measure : float, bpm : float, time_sig_numerator : float = 4.0):
	return measure * (60000.0 / (bpm / time_sig_numerator))

static func ms_to_measures(ms : float, bpm_list : Array[BpmInfo]) -> float:
	var ms_times : Dictionary[BpmInfo, float] = get_ms_for_bpms(bpm_list)
	var bpm : BpmInfo = bpm_list[get_bpm_index_from_ms(ms, bpm_list)]
	var measure_value : float = measure_to_ms(1.0, bpm.Bpm, bpm.TimeSignatureNumerator)
	var offset : float = ms - ms_times[bpm]
	return bpm.Time + (offset / measure_value)

static func get_bpm_index_from_ms(ms : float, bpm_changes : Array[BpmInfo]) -> int:
	var ms_times : Dictionary[BpmInfo, float] = get_ms_for_bpms(bpm_changes)
	var bpm_index : int = bpm_changes.size() - 1
	for i in bpm_changes.size():
		if ms_times[bpm_changes[i]] > ms:
			bpm_index = i - 1
			break
				
	return bpm_index

static func get_ms_for_bpms(bpm_list : Array[BpmInfo]) -> Dictionary[BpmInfo, float]:
	var bpm_map : Dictionary[BpmInfo, float] = { bpm_list[0]: 0.0 }
	for i in range(1, bpm_list.size()):
		var current_bpm : BpmInfo = bpm_list[i]
		var last_bpm : BpmInfo = bpm_list[i - 1]
		bpm_map[bpm_list[i]] = bpm_map[last_bpm] + measure_to_ms(current_bpm.Time - last_bpm.Time, last_bpm.Bpm, current_bpm.TimeSignatureNumerator)
	
	return bpm_map
	
static func get_length_from_ms(start_ms : float, end_ms : float, bpm_list : Array[BpmInfo]) -> float:
	return ms_to_measures(end_ms, bpm_list) - ms_to_measures(start_ms, bpm_list)
