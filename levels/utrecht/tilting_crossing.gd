extends AnimatableBody2D

signal creaking
signal support_broke

const LENGTH := 504.0
const TIP := Vector2(LENGTH, -46.0)
const WARNING_S := 0.55
const FALL_S := 0.72
const MAX_TILT := 0.305
var elapsed := -1.0
var _sound: AudioStreamPlayer2D

func _ready() -> void:
	sync_to_physics = false
	collision_mask = 0
	var segment := SegmentShape2D.new()
	segment.a = Vector2.ZERO
	segment.b = TIP
	var shape := CollisionShape2D.new()
	shape.shape = segment
	add_child(shape)
	_sound = AudioStreamPlayer2D.new()
	_sound.stream = _make_creak()
	_sound.volume_db = -13.0
	add_child(_sound)

func reset() -> void:
	elapsed = -1.0
	rotation = 0.0
	_sound.stop()
	queue_redraw()

func advance(delta: float, loaded: bool) -> void:
	if elapsed < 0.0:
		if not loaded:
			return
		elapsed = 0.0
		_sound.play()
		creaking.emit()
	var previous := elapsed
	elapsed = minf(WARNING_S + FALL_S, elapsed + delta)
	if previous < WARNING_S and elapsed >= WARNING_S:
		support_broke.emit()
	rotation = MAX_TILT * smoothstep(WARNING_S, WARNING_S + FALL_S, elapsed)
	queue_redraw()

func _make_creak() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 16000
	var pcm := PackedByteArray()
	pcm.resize(14400)
	for i in range(7200):
		var t := float(i) / 16000.0
		var envelope := sin(PI * t / 0.45) * (0.45 + 0.55 * sin(44.0 * t) ** 2)
		var wave := sin(TAU * (82.0 * t - 48.0 * t * t)) + 0.45 * sin(TAU * (163.0 * t - 43.0 * t * t))
		pcm.encode_s16(i * 2, roundi(wave * envelope * 11500.0))
	stream.data = pcm
	return stream



