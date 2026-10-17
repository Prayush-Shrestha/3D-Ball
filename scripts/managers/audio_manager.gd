extends Node
## AudioManager (autoload) - soft, relaxing procedural audio, no files needed.
## Bus layout uses Master only (built-in) to avoid missing-bus errors.
## SFX use warm 16-bit sine chimes with smooth envelopes (no harsh 8-bit buzz).
## A quiet generative pad loop plays as background music (music_volume slider).

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
const POOL_SIZE := 8
const SAMPLE_RATE := 22050

var _roll_player: AudioStreamPlayer = null
var _roll_level := 0.0
var _roll_target := 0.0

var _music_player: AudioStreamPlayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	# Warm relaxing chimes (pentatonic, soft attack, smooth decay).
	_streams["jump"] = _make_glide(329.63, 440.0, 0.22, 0.42, 0.012)
	_streams["collect"] = _make_glide(987.77, 1318.51, 0.30, 0.30, 0.008)
	_streams["checkpoint"] = _make_pad_hit([261.63, 329.63, 392.0], 0.7, 0.38)
	_streams["hurt"] = _make_glide(196.0, 130.81, 0.28, 0.34, 0.01)
	_streams["win"] = _make_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.22, 0.38)
	_streams["click"] = _make_glide(880.0, 880.0, 0.07, 0.20, 0.008)
	_streams["respawn"] = _make_glide(311.13, 622.25, 0.38, 0.32, 0.05)
	_roll_player = AudioStreamPlayer.new()
	_roll_player.bus = "Master"
	_roll_player.stream = _make_soft_wind_loop()
	_roll_player.volume_db = -60.0
	add_child(_roll_player)
	_roll_player.play()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.stream = _make_ambient_loop()
	add_child(_music_player)
	_music_player.play()
	apply_volumes()


func apply_volumes() -> void:
	# Master slider drives the bus; music/sfx sliders scale their players so
	# every slider in Settings actually does something (old code ignored music).
	var master := 1.0
	var music := 0.8
	var sfx := 1.0
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		master = sm.master_volume
		music = sm.music_volume
		sfx = sm.sfx_volume
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.001)))
	if _music_player != null:
		if music <= 0.01:
			_music_player.volume_db = -60.0
		else:
			# Quiet background bed: -30..-15 dB.
			_music_player.volume_db = lerpf(-30.0, -15.0, clampf(music, 0.0, 1.0))
	# SFX loudness is applied per-play in play_sfx() from sfx_volume.


func play_sfx(sfx_name: String) -> void:
	if not _streams.has(sfx_name):
		return
	var sfx := 1.0
	if has_node("/root/SaveManager"):
		sfx = get_node("/root/SaveManager").sfx_volume
	var db := linear_to_db(maxf(sfx, 0.001))
	for p in _players:
		if not p.playing:
			p.stream = _streams[sfx_name]
			p.volume_db = db
			p.pitch_scale = 1.0
			p.play()
			return
	# All busy: steal the first one.
	_players[0].stream = _streams[sfx_name]
	_players[0].volume_db = db
	_players[0].play()


func play_custom(stream: AudioStreamWAV) -> void:
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_players[0].stream = stream
	_players[0].play()


func set_rolling(intensity: float) -> void:
	# Called every physics frame by the ball (0 = still/air, 1 = full speed).
	_roll_target = clampf(intensity, 0.0, 1.0)


func _process(delta: float) -> void:
	var sfx := 1.0
	if has_node("/root/SaveManager"):
		sfx = get_node("/root/SaveManager").sfx_volume
	var sfx_db := linear_to_db(maxf(sfx, 0.001))
	if _roll_player != null:
		var t := _roll_target
		if get_tree().paused:
			t = 0.0
		_roll_level = lerpf(_roll_level, t, minf(1.0, delta * 8.0))
		if _roll_level < 0.02:
			_roll_player.volume_db = -60.0
		else:
			# Soft airy roll, quieter than before: -36..-24 dB + sfx scale.
			_roll_player.volume_db = lerpf(-36.0, -24.0, _roll_level) + sfx_db
		_roll_player.pitch_scale = lerpf(0.7, 1.15, _roll_level)


# --- 16-bit helpers ---

func _new_16bit(frames: int) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SAMPLE_RATE
	s.stereo = false
	s.data = PackedByteArray()
	s.data.resize(frames * 2)
	return s


func _put(stream: AudioStreamWAV, idx: int, sample: float) -> void:
	var v := int(clampf(sample, -1.0, 1.0) * 32767.0)
	if v < -32768:
		v = -32768
	if v > 32767:
		v = 32767
	if v < 0:
		v += 65536
	stream.data[idx * 2] = v & 0xFF
	stream.data[idx * 2 + 1] = (v >> 8) & 0xFF


func _soft_env(pos: float, attack: float) -> float:
	# pos 0..1 across the sound. Smooth sine attack, gentle exp release.
	# Avoids the clicks that made the old 8-bit tones harsh.
	var a := clampf(attack, 0.004, 0.25)
	var e := 1.0
	if pos < a:
		e = 0.5 - 0.5 * cos(PI * pos / a)
	else:
		var r := (pos - a) / maxf(0.0001, 1.0 - a)
		e = pow(1.0 - r, 1.6)
	return e


func _warm(freq: float, t: float) -> float:
	# Fundamental + soft octave + fifth shimmer for a bell-like warmth.
	return sin(TAU * freq * t) * 0.78 + sin(TAU * freq * 2.0 * t) * 0.16 + sin(TAU * freq * 3.0 * t) * 0.06


func _make_glide(freq_from: float, freq_to: float, duration: float, volume: float, attack: float) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * duration)
	var s := _new_16bit(frames)
	var phase := 0.0
	for i in frames:
		var pos := float(i) / float(maxi(1, frames))
		var f := lerpf(freq_from, freq_to, pos)
		phase += TAU * f / SAMPLE_RATE
		var tone := sin(phase) * 0.8 + sin(phase * 2.0) * 0.15 + sin(phase * 3.0) * 0.05
		_put(s, i, tone * _soft_env(pos, attack / maxf(0.01, duration)) * volume)
	return s


func _make_pad_hit(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * duration)
	var s := _new_16bit(frames)
	for i in frames:
		var pos := float(i) / float(maxi(1, frames))
		var t := float(i) / SAMPLE_RATE
		var m := 0.0
		for f in freqs:
			m += _warm(float(f), t)
		m /= float(maxi(1, freqs.size()))
		_put(s, i, m * _soft_env(pos, 0.12) * volume)
	return s


func _make_arpeggio(notes: Array, note_len: float, volume: float) -> AudioStreamWAV:
	# Overlapping notes with long tails = dreamy victory instead of beeps.
	var tail := 0.45
	var total := note_len * float(notes.size()) + tail
	var frames := int(SAMPLE_RATE * total)
	var s := _new_16bit(frames)
	for n in notes.size():
		var start := int(n * SAMPLE_RATE * note_len)
		var dur := note_len + tail
		var count := int(SAMPLE_RATE * dur)
		var freq := float(notes[n])
		for i in count:
			var idx := start + i
			if idx >= frames:
				break
			var pos := float(i) / float(maxi(1, count))
			var t := float(i) / SAMPLE_RATE
			var cur := _warm(freq, t) * _soft_env(pos, 0.02) * volume * 0.7
			# Mix additively with whatever is already in the buffer.
			var lo := s.data[idx * 2]
			var hi := s.data[idx * 2 + 1]
			var raw := lo + (hi << 8)
			if raw >= 32768:
				raw -= 65536
			var mixed := float(raw) / 32767.0 + cur
			_put(s, idx, mixed)
	return s


func _make_soft_wind_loop() -> AudioStreamWAV:
	# Heavily smoothed noise = soft rolling air, not static hiss.
	var frames := SAMPLE_RATE # 1 second, seamlessly looped
	var s := _new_16bit(frames)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = frames
	var v := 0.0
	var lfo_phase := 0.0
	for i in frames:
		v += (randf() * 2.0 - 1.0) * 0.06
		v *= 0.996
		lfo_phase += TAU * 0.4 / SAMPLE_RATE
		var breeze := 0.75 + 0.25 * sin(lfo_phase)
		_put(s, i, v * breeze * 0.5)
	# Crossfade tail into head for click-free looping.
	var fade := 4000
	for i in fade:
		var a := float(i) / float(fade)
		var tail_idx := frames - fade + i
		var lo_t := s.data[tail_idx * 2]
		var hi_t := s.data[tail_idx * 2 + 1]
		var raw_t := lo_t + (hi_t << 8)
		if raw_t >= 32768:
			raw_t -= 65536
		var lo_h := s.data[i * 2]
		var hi_h := s.data[i * 2 + 1]
		var raw_h := lo_h + (hi_h << 8)
		if raw_h >= 32768:
			raw_h -= 65536
		_put(s, tail_idx, lerpf(float(raw_t) / 32767.0, float(raw_h) / 32767.0, a))
	return s


func _make_ambient_loop() -> AudioStreamWAV:
	# 4-second dreamy pad: Am - F - C - G, one chord per second, slow attack.
	# Quiet by design; volume comes from apply_volumes() + music slider.
	var chords := [
		[220.0, 261.63, 329.63], # Am
		[174.61, 220.0, 261.63], # F
		[130.81, 196.0, 261.63], # C
		[196.0, 246.94, 293.66], # G
	]
	var sec_per := 1.0
	var total := sec_per * float(chords.size())
	var frames := int(SAMPLE_RATE * total)
	var s := _new_16bit(frames)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = frames
	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var ci := int(t / sec_per) % chords.size()
		var cn: Array = chords[ci]
		# Crossfade 0.4s between chords so the loop breathes.
		var m := 0.0
		for f in cn:
			m += _warm(float(f), t) * 0.5 + _warm(float(f) * 0.5, t) * 0.25
		m /= float(maxi(1, cn.size()))
		var lfo := 0.8 + 0.2 * sin(TAU * 0.25 * t)
		_put(s, i, m * lfo * 0.30)
	# Seamless loop crossfade over last 0.5s.
	var fade := int(SAMPLE_RATE * 0.5)
	for i in fade:
		var a := float(i) / float(fade)
		var tail_idx := frames - fade + i
		var lo_t := s.data[tail_idx * 2]
		var hi_t := s.data[tail_idx * 2 + 1]
		var raw_t := lo_t + (hi_t << 8)
		if raw_t >= 32768:
			raw_t -= 65536
		var lo_h := s.data[i * 2]
		var hi_h := s.data[i * 2 + 1]
		var raw_h := lo_h + (hi_h << 8)
		if raw_h >= 32768:
			raw_h -= 65536
		_put(s, tail_idx, lerpf(float(raw_t) / 32767.0, float(raw_h) / 32767.0, a))
	return s
