extends Node
## AudioManager (autoload) - procedural sound effects, no audio files required.
## Place optional custom files in res://assets/audio/ and call play_custom().
## Bus layout uses Master only (built-in) to avoid missing-bus errors.

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
const POOL_SIZE := 8
const SAMPLE_RATE := 22050


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_streams["jump"] = _make_tone(300.0, 620.0, 0.18, 0.5)
	_streams["collect"] = _make_tone(880.0, 1560.0, 0.22, 0.45)
	_streams["checkpoint"] = _make_tone(440.0, 880.0, 0.35, 0.5)
	_streams["hurt"] = _make_tone(320.0, 120.0, 0.30, 0.55)
	_streams["win"] = _make_win_jingle()
	_streams["click"] = _make_tone(660.0, 660.0, 0.07, 0.35)
	_streams["respawn"] = _make_tone(200.0, 500.0, 0.25, 0.45)
	apply_volumes()


func apply_volumes() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var master_db := linear_to_db(maxf(sm.master_volume, 0.001))
	var sfx_db := linear_to_db(maxf(sm.sfx_volume, 0.001))
	AudioServer.set_bus_volume_db(0, master_db + (sfx_db * 0.5))


func play_sfx(sfx_name: String) -> void:
	if not _streams.has(sfx_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sfx_name]
			p.play()
			return
	# All busy: steal the first one.
	_players[0].stream = _streams[sfx_name]
	_players[0].play()


func _make_tone(freq_from: float, freq_to: float, duration: float, volume: float) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames)
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var f := lerpf(freq_from, freq_to, float(i) / maxf(1.0, float(frames)))
		var env := 1.0 - (float(i) / float(frames))
		var s := sin(TAU * f * t) * env * volume
		data[i] = int(clampf(s * 0.5 + 0.5, 0.0, 1.0) * 255.0)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _make_win_jingle() -> AudioStreamWAV:
	var notes := [523.0, 659.0, 784.0, 1046.0]
	var note_len := 0.14
	var frames := int(SAMPLE_RATE * note_len * notes.size())
	var data := PackedByteArray()
	data.resize(frames)
	for n in notes.size():
		var start := n * int(SAMPLE_RATE * note_len)
		var count := int(SAMPLE_RATE * note_len)
		for i in count:
			var idx := start + i
			if idx >= frames:
				break
			var t := float(i) / SAMPLE_RATE
			var env := 1.0 - (float(i) / float(count))
			var s := sin(TAU * notes[n] * t) * env * 0.45
			data[idx] = int(clampf(s * 0.5 + 0.5, 0.0, 1.0) * 255.0)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
