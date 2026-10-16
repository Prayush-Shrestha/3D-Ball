extends Node
## AudioManager (autoload) - procedural sound effects, no audio files required.
## Place optional custom files in res://assets/audio/ and call play_custom().
## Bus layout uses Master only (built-in) to avoid missing-bus errors.

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
const POOL_SIZE := 8
const SAMPLE_RATE := 22050

var _roll_player: AudioStreamPlayer = null
var _roll_level := 0.0
var _roll_target := 0.0


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
	_roll_player = AudioStreamPlayer.new()
	_roll_player.bus = "Master"
	_roll_player.stream = _make_roll_loop()
	_roll_player.volume_db = -60.0
	add_child(_roll_player)
	_roll_player.play()
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


func set_rolling(intensity: float) -> void:
	# Called every physics frame by the ball (0 = still/air, 1 = full speed).
	_roll_target = clampf(intensity, 0.0, 1.0)


func _process(delta: float) -> void:
	if _roll_player == null:
		return
	var t := _roll_target
	if get_tree().paused:
		t = 0.0
	_roll_level = lerpf(_roll_level, t, minf(1.0, delta * 8.0))
	if _roll_level < 0.02:
		_roll_player.volume_db = -60.0
	else:
		_roll_player.volume_db = lerpf(-34.0, -16.0, _roll_level)
	_roll_player.pitch_scale = lerpf(0.7, 1.25, _roll_level)


func _make_roll_loop() -> AudioStreamWAV:
	# Soft looped rumble: smoothed random walk, ends crossfaded for clean loop.
	var frames := SAMPLE_RATE  # 1 second
	var data := PackedByteArray()
	data.resize(frames)
	var v := 0.0
	for i in frames:
		v += (randf() * 2.0 - 1.0) * 0.25
		v *= 0.985
		data[i] = int(clampf(v * 0.5 + 0.5, 0.0, 1.0) * 255.0)
	var fade := 4000
	for i in fade:
		var a := float(i) / float(fade)
		var tail_idx := frames - fade + i
		data[tail_idx] = int(lerpf(float(data[tail_idx]), float(data[i]), a))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	stream.data = data
	return stream


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
