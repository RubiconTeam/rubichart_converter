static var addon_path : String = ""

static func measure_to_ms(measure : float, bpm : float, time_sig_numerator : float = 4.0):
	return measure * (60000.0 / (bpm / time_sig_numerator))
